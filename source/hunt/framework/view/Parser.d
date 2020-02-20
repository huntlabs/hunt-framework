/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.view.Parser;

public
{
    import hunt.framework.view.Lexer : Position;
}

private
{
    import std.array : appender;
    import std.conv : to;
    import std.file : exists, read;
    import std.path : dirName,absolutePath,dirSeparator;
    import std.format: fmt = format;
    import std.range;

    import hunt.logging;
    import hunt.framework.view.ast;
    import hunt.framework.view.Lexer;
    import hunt.framework.view.Exception : TemplateParserException,
                              assertTemplate = assertTemplateParser;
}


final class Parser(Lexer)
{
    struct ParserState
    {
        Token[] tokens;
        BlockNode[string] blocks;
    }

    private
    {
        TemplateNode[string] _parsedFiles;
        bool _cacheEnabled = true;

        Token[] _tokens;
        BlockNode[string] _blocks;

        ParserState[] _states;
    }

    bool cacheEnabled() {
        return _cacheEnabled;
    }

    void cacheEnabled(bool value) {
        _cacheEnabled = value;
    }

    void preprocess()
    {
        import std.string : stripRight, stripLeft;

        auto newTokens = appender!(Token[]);

        for (int i = 0; i < _tokens.length;)
        {
            if (i < _tokens.length - 1
                && _tokens[i] == Type.StmtBegin
                && _tokens[i+1] == Operator.Minus)
            {
                newTokens.put(_tokens[i]);
                i += 2;
            }
            else if(i < _tokens.length - 1
                    && _tokens[i] == Operator.Minus
                    && _tokens[i+1] == Type.StmtEnd)
            {
                newTokens.put(_tokens[i+1]);
                i += 2;
            }
            else if (_tokens[i] == Type.Raw)
            {
                bool stripR = false;
                bool stripL = false;
                bool stripInlineR = false;

                if (i >= 2 
                    && _tokens[i-2] == Operator.Minus
                    && _tokens[i-1] == Type.StmtEnd
                    )
                    stripL = true;

                if (i < _tokens.length - 2 && _tokens[i+1] == Type.StmtBegin)
                {
                    if (_tokens[i+2] == Operator.Minus)
                        stripR = true;
                    else if (_tokens[i+1].value == Lexer.stmtInline)
                        stripInlineR = true;
                }

                auto str = _tokens[i].value;
                str = stripR ? str.stripRight : str;
                str = stripL ? str.stripLeft : str;
                str = stripInlineR ? str.stripOnceRight : str;
                newTokens.put(Token(Type.Raw, str, _tokens[i].pos));
                i++;
            }
            else
            {
                newTokens.put(_tokens[i]);
                i++;
            }
        }
        _tokens = newTokens.data;
    }


    TemplateNode parseTree(string str, string filename ,string dirPath)
    {
        stashState();

        auto lexer = Lexer(str, filename);
        auto newTokens = appender!(Token[]);

        while (true)
        {
            auto tkn = lexer.nextToken;
            newTokens.put(tkn); 
            if (tkn.type == Type.EOF)
                break;
        }
        _tokens = newTokens.data;

        preprocess();

        auto root = parseStatementBlock(dirPath);
        auto blocks = _blocks;

        if (front.type != Type.EOF)
            assertTemplate(0, "Expected EOF found %s(%s)".fmt(front.type, front.value), front.pos);

        popState();

        return new TemplateNode(Position(filename, 1, 1), root, blocks);
    }


    TemplateNode parseTreeFromFile(string path)
    {
        if(_cacheEnabled) {
            // path = path.absolute(_path);
            version(HUNT_FM_DEBUG) logDebugf("parse file absolute path(%d): %s", _parsedFiles.length, path);
            auto cached = path in _parsedFiles;
            if (cached !is null)
            {
                if (*cached is null) {
                    assertTemplate(0, fmt("Recursive imports/includes/extends not allowed: %s", path), front.pos);
                } else {
                    return *cached;
                }
            }

            string dirPath = dirName(path) ~ dirSeparator;
            // Prevent recursive imports
            _parsedFiles[path] = null;
            auto str = cast(string)read(path);
            TemplateNode r = parseTree(str, path, dirPath);
            _parsedFiles[path] = r;

            return r;
        } else {
            string dirPath = dirName(path) ~ dirSeparator;
            auto str = cast(string)read(path);
            return parseTree(str, path, dirPath);
        }
    }


private:
    /**
      * exprblock = EXPRBEGIN expr (IF expr (ELSE expr)? )? EXPREND
      */
    ExprNode parseExpression(string dirPath)
    {
        Node expr;
        auto pos = front.pos;

        pop(Type.ExprBegin);
        expr = parseHighLevelExpression(dirPath);
        pop(Type.ExprEnd);

        return new ExprNode(pos, expr);
    }

    StmtBlockNode parseStatementBlock(string dirPath)
    {
        auto block = new StmtBlockNode(front.pos);

        while (front.type != Type.EOF)
        {
            auto pos = front.pos;
            switch(front.type) with (Type)
            {
                case Raw:
                    auto raw = pop.value;
                    if (raw.length)
                        block.children ~= new RawNode(pos, raw);
                    break;

                case ExprBegin:
                    block.children ~= parseExpression(dirPath);
                    break;

                case CmntBegin:
                    parseComment(dirPath);
                    break;

                case CmntInline:
                    pop();
                    break;

                case StmtBegin:
                    if (next.type == Type.Keyword
                        && next.value.toKeyword.isBeginingKeyword)
                        block.children ~= parseStatement(dirPath);
                    else
                        return block;
                    break;

                default:
                    return block;
            }
        }

        return block;
    }


    Node parseStatement(string dirPath)
    {
        pop(Type.StmtBegin);

        switch(front.value) with (Keyword)
        {
            case If:      return parseIf(dirPath);
            case For:     return parseFor(dirPath);
            case Set:     return parseSet(dirPath);
            case Macro:   return parseMacro(dirPath);
            case Call:    return parseCall(dirPath);
            case Filter:  return parseFilterBlock(dirPath);
            case With:    return parseWith(dirPath);
            case Import:  return parseImport(dirPath);
            case From:    return parseImportFrom(dirPath);
            case Include: return parseInclude(dirPath);
            case Extends: return parseExtends(dirPath);

            case Block:
                auto block = parseBlock( dirPath);
                _blocks[block.name] = block;
                return block;
            default:
                assert(0, "Not implemented kw %s".fmt(front.value));
        }
    }


    ForNode parseFor(string dirPath)
    {
        string[] keys;
        bool isRecursive = false;
        Node cond = null;
        auto pos = front.pos;

        pop(Keyword.For);

        keys ~= pop(Type.Ident).value;
        while(front != Operator.In)
        {
            pop(Type.Comma);
            keys ~= pop(Type.Ident).value;
        }

        pop(Operator.In);

        Node iterable;

        switch (front.type) with (Type)
        {
            case LParen:  iterable = parseTuple(dirPath); break;
            case LSParen: iterable = parseList(dirPath); break;
            case LBrace:  iterable = parseDict(dirPath); break;
            default:      iterable = parseIdent(dirPath);
        }

        if (front == Keyword.If)
        {
            pop(Keyword.If);
            cond = parseHighLevelExpression(dirPath);
        }

        if (front == Keyword.Recursive)
        {
            pop(Keyword.Recursive);
            isRecursive = true;
        }

        pop(Type.StmtEnd);

        auto block = parseStatementBlock(dirPath);

        pop(Type.StmtBegin);

        switch (front.value) with (Keyword)
        {
            case EndFor:
                pop(Keyword.EndFor);
                pop(Type.StmtEnd);
                return new ForNode(pos, keys, iterable, block, null, cond, isRecursive);
            case Else:
                pop(Keyword.Else);
                pop(Type.StmtEnd);
                auto other = parseStatementBlock(dirPath);
                pop(Type.StmtBegin);
                pop(Keyword.EndFor);
                pop(Type.StmtEnd);
                return new ForNode(pos, keys, iterable, block, other, cond, isRecursive);
            default:
                assertTemplate(0, "Unexpected token %s(%s)".fmt(front.type, front.value), front.pos);
                assert(0);
        }
    }


    IfNode parseIf(string dirPath)
    {
        auto pos = front.pos;
        assertTemplate(front == Keyword.If || front == Keyword.ElIf, "Expected If/Elif", pos);
        pop();
        auto cond = parseHighLevelExpression(dirPath);
        pop(Type.StmtEnd);

        auto then = parseStatementBlock(dirPath);

        pop(Type.StmtBegin);

        switch (front.value) with (Keyword)
        {
            case ElIf:
                auto other = parseIf(dirPath);
                return new IfNode(pos, cond, then, other);
            case Else:
                pop(Keyword.Else, Type.StmtEnd);
                auto other = parseStatementBlock(dirPath);
                pop(Type.StmtBegin, Keyword.EndIf, Type.StmtEnd);
                return new IfNode(pos, cond, then, other);
            case EndIf:
                pop(Keyword.EndIf, Type.StmtEnd);
                return new IfNode(pos, cond, then, null);
            default:
                assertTemplate(0, "Unexpected token %s(%s)".fmt(front.type, front.value), front.pos);
                assert(0);
        }
    }


    SetNode parseSet(string dirPath)
    {
        auto setPos = front.pos;

        pop(Keyword.Set);

        auto assigns = parseSequenceOf!parseAssignable(dirPath,Type.Operator);

        pop(Operator.Assign);

        auto listPos = front.pos;
        auto exprs = parseSequenceOf!parseHighLevelExpression(dirPath,Type.StmtEnd);
        Node expr = exprs.length == 1 ? exprs[0] : new ListNode(listPos, exprs);

        pop(Type.StmtEnd);

        return new SetNode(setPos, assigns, expr);
    }


    AssignableNode parseAssignable(string dirPath)
    {
        auto pos = front.pos;
        string name = pop(Type.Ident).value;
        Node[] subIdents = [];

        while (true)
        {
            switch (front.type) with (Type)
            {
                case Dot:
                    pop(Dot);
                    auto strPos = front.pos;
                    subIdents ~= new StringNode(strPos, pop(Ident).value);
                    break;
                case LSParen:
                    pop(LSParen);
                    subIdents ~= parseHighLevelExpression(dirPath);
                    pop(RSParen);
                    break;
                default:
                    return new AssignableNode(pos, name, subIdents);
            }
        }
    }


    MacroNode parseMacro(string dirPath)
    {
        auto pos = front.pos;
        pop(Keyword.Macro);

        auto name = pop(Type.Ident).value;
        Arg[] args;

        if (front.type == Type.LParen)
        {
            pop(Type.LParen);
            args = parseFormalArgs( dirPath);
            pop(Type.RParen);
        }

        pop(Type.StmtEnd);

        auto block = parseStatementBlock( dirPath);

        pop(Type.StmtBegin, Keyword.EndMacro);

        bool ret = false;
        if (front.type == Type.Keyword && front.value == Keyword.Return)
        {
            pop(Keyword.Return);
            block.children ~= parseHighLevelExpression(dirPath);
            ret = true;
        }
        else
            block.children ~= new NilNode; // void return

        pop(Type.StmtEnd);

        return new MacroNode(pos, name, args, block, ret);
    }


    CallNode parseCall(string dirPath)
    {
        auto pos = front.pos;
        pop(Keyword.Call);

        Arg[] formalArgs;

        if (front.type == Type.LParen)
        {
            pop(Type.LParen);
            formalArgs = parseFormalArgs( dirPath);
            pop(Type.RParen);
        }

        auto macroName = front.value;
        auto factArgs = parseCallExpr( dirPath);

        pop(Type.StmtEnd);

        auto block = parseStatementBlock( dirPath);
        block.children ~= new NilNode; // void return

        pop(Type.StmtBegin, Keyword.EndCall, Type.StmtEnd);

        return new CallNode(pos, macroName, formalArgs, factArgs, block);
    }


    FilterBlockNode parseFilterBlock(string dirPath)
    {
        auto pos = front.pos;
        pop(Keyword.Filter);

        auto filterName = front.value;
        auto args = parseCallExpr(dirPath);

        pop(Type.StmtEnd);

        auto block = parseStatementBlock(dirPath);

        pop(Type.StmtBegin, Keyword.EndFilter, Type.StmtEnd);

        return new FilterBlockNode(pos, filterName, args, block);
    }

    StmtBlockNode parseWith(string dirPath)
    {
        pop(Keyword.With, Type.StmtEnd);
        auto block = parseStatementBlock(dirPath);
        pop(Type.StmtBegin, Keyword.EndWith, Type.StmtEnd);

        return block;
    }


    ImportNode parseImport(string dirPath)
    {
        auto pos = front.pos;
        pop(Keyword.Import);
        auto path = pop(Type.String).value.absolute(dirPath);
        bool withContext = false;

        if (front == Keyword.With)
        {
            withContext = true;
            pop(Keyword.With, Keyword.Context);
        }

        if (front == Keyword.Without)
        {
            withContext = false;
            pop(Keyword.Without, Keyword.Context);
        }

        pop(Type.StmtEnd);

        assertTemplate(path.fileExist(dirPath), "Non existing file `%s`".fmt(path), pos);

        auto stmtBlock = parseTreeFromFile(path);

        return new ImportNode(pos, path, cast(ImportNode.Rename[])[], stmtBlock, withContext);
    }


    ImportNode parseImportFrom(string dirPath)
    {
        auto pos = front.pos;
        pop(Keyword.From);
        auto path = pop(Type.String).value.absolute(dirPath);
        pop(Keyword.Import);

        ImportNode.Rename[] macros;

        bool firstName = true;
        while (front == Type.Comma || firstName)
        {
            if (!firstName)
                pop(Type.Comma);

            auto was = pop(Type.Ident).value;
            auto become = was;

            if (front == Keyword.As)
            {
                pop(Keyword.As);
                become = pop(Type.Ident).value;
            }

            macros ~= ImportNode.Rename(was, become);

            firstName = false;
        }

        bool withContext = false;

        if (front == Keyword.With)
        {
            withContext = true;
            pop(Keyword.With, Keyword.Context);
        }

        if (front == Keyword.Without)
        {
            withContext = false;
            pop(Keyword.Without, Keyword.Context);
        }

        pop(Type.StmtEnd);

        assertTemplate(path.fileExist(dirPath), "Non existing file `%s`".fmt(path), pos);

        auto stmtBlock = parseTreeFromFile(path);

        return new ImportNode(pos, path, macros, stmtBlock, withContext);
    }


    IncludeNode parseInclude(string dirPath)
    {
        auto pos = front.pos;
        pop(Keyword.Include);

        string[] names;

        if (front == Type.LSParen)
        {
            pop(Type.LSParen);

            names ~= pop(Type.String).value;
            while (front == Type.Comma)
            {
                pop(Type.Comma);
                names ~= pop(Type.String).value;
            }

            pop(Type.RSParen);
        }
        else
            names ~= pop(Type.String).value;


        bool ignoreMissing = false;
        if (front == Keyword.Ignore)
        {
            pop(Keyword.Ignore, Keyword.Missing);
            ignoreMissing = true;
        }

        bool withContext = true;

        if (front == Keyword.With)
        {
            withContext = true;
            pop(Keyword.With, Keyword.Context);
        }

        if (front == Keyword.Without)
        {
            withContext = false;
            pop(Keyword.Without, Keyword.Context);
        }

        pop(Type.StmtEnd);

        foreach (name; names)
            if (name.fileExist(dirPath))
                return new IncludeNode(pos, name, parseTreeFromFile(dirPath ~ name), withContext);
 
        assertTemplate(ignoreMissing, "No existing files `%s`".fmt(names), pos);

        return new IncludeNode(pos, "", null, withContext);
    }


    ExtendsNode parseExtends(string dirPath)
    {
        auto pos = front.pos;
        pop(Keyword.Extends);
        auto path = pop(Type.String).value.absolute(dirPath);
        pop(Type.StmtEnd);

        assertTemplate(path.fileExist(dirPath), "Non existing file `%s`".fmt(path), pos);

        auto stmtBlock = parseTreeFromFile(path);

        return new ExtendsNode(pos, path, stmtBlock);
    }


    BlockNode parseBlock(string dirPath)
    {
        auto pos = front.pos;
        pop(Keyword.Block);
        auto name = pop(Type.Ident).value;
        pop(Type.StmtEnd);

        auto stmt = parseStatementBlock( dirPath);

        pop(Type.StmtBegin, Keyword.EndBlock);

        auto posNameEnd = front.pos;
        if (front == Type.Ident)
            assertTemplate(pop.value == name, "Missmatching block's begin/end names", posNameEnd);

        pop(Type.StmtEnd);

        return new BlockNode(pos, name, stmt);
    }

    Arg[] parseFormalArgs(string dirPath)
    {
        Arg[] args = [];
        bool isVarargs = true;

        while(front.type != Type.EOF && front.type != Type.RParen)
        {
            auto name = pop(Type.Ident).value;
            Node def = null;

            if (!isVarargs || front.type == Type.Operator && front.value == Operator.Assign)
            {
                isVarargs = false;
                pop(Operator.Assign);
                def = parseHighLevelExpression(dirPath);
            }

            args ~= Arg(name, def);

            if (front.type != Type.RParen)
                pop(Type.Comma);
        }
        return args;
    }


    Node parseHighLevelExpression(string dirPath)
    {
        return parseInlineIf(dirPath);
    }


    /**
      * inlineif = orexpr (IF orexpr (ELSE orexpr)? )?
      */
    Node parseInlineIf(string dirPath)
    {
        Node expr;
        Node cond = null;
        Node other = null;

        auto pos = front.pos;
        expr = parseOrExpr( dirPath);

        if (front == Keyword.If)
        {
            pop(Keyword.If);
            cond = parseOrExpr( dirPath);

            if (front == Keyword.Else)
            {
                pop(Keyword.Else);
                other = parseOrExpr(dirPath);
            }

            return new InlineIfNode(pos, expr, cond, other);
        }

        return expr;
    }

    /**
      * Parse Or Expression
      * or = and (OR or)?
      */
    Node parseOrExpr(string dirPath)
    {
        auto lhs = parseAndExpr(dirPath);

        while(true)
        {
            if (front.type == Type.Operator && front.value == Operator.Or)
            {
                auto pos = front.pos;
                pop(Operator.Or);
                auto rhs = parseAndExpr( dirPath);
                lhs = new BinOpNode(pos, Operator.Or, lhs, rhs);
            }
            else
                return lhs;
        }
    }

    /**
      * Parse And Expression:
      * and = inis (AND inis)*
      */
    Node parseAndExpr(string dirPath)
    {
        auto lhs = parseInIsExpr( dirPath);

        while(true)
        {
            if (front.type == Type.Operator && front.value == Operator.And)
            {
                auto pos = front.pos;
                pop(Operator.And);
                auto rhs = parseInIsExpr( dirPath);
                lhs = new BinOpNode(pos, Operator.And, lhs, rhs);
            }
            else
                return lhs;
        }
    }

    /**
      * Parse inis:
      * inis = cmp ( (NOT)? (IN expr |IS callexpr) )?
      */
    Node parseInIsExpr(string dirPath)
    {
        auto inis = parseCmpExpr( dirPath);

        auto notPos = front.pos;
        bool hasNot = false;
        if (front == Operator.Not && (next == Operator.In || next == Operator.Is))
        {
            pop(Operator.Not);
            hasNot = true;
        }

        auto inisPos = front.pos;

        if (front == Operator.In)
        {
            auto op = pop().value;
            auto rhs = parseHighLevelExpression( dirPath);
            inis = new BinOpNode(inisPos, op, inis, rhs);
        }

        if (front == Operator.Is)
        {
            auto op = pop().value;
            auto rhs = parseCallExpr( dirPath);
            inis = new BinOpNode(inisPos, op, inis, rhs);
        }

        if (hasNot)
            inis = new UnaryOpNode(notPos, Operator.Not, inis);

        return inis;
    }


    /**
      * Parse compare expression:
      * cmp = concatexpr (CMPOP concatexpr)?
      */
    Node parseCmpExpr(string dirPath)
    {
        auto lhs = parseConcatExpr( dirPath);

        if (front.type == Type.Operator && front.value.toOperator.isCmpOperator)
        {
            auto pos = front.pos;
            auto op = pop(Type.Operator).value;
            return new BinOpNode(pos, op, lhs, parseConcatExpr( dirPath));
        }

        return lhs;
    }

    /**
      * Parse expression:
      * concatexpr = filterexpr (CONCAT filterexpr)*
      */
    Node parseConcatExpr(string dirPath)
    {
        auto lhsTerm = parseFilterExpr( dirPath);

        while (front == Operator.Concat)
        {
            auto pos = front.pos;
            auto op = pop(Operator.Concat).value;
            lhsTerm = new BinOpNode(pos, op, lhsTerm, parseFilterExpr( dirPath));
        }

        return lhsTerm;
    }

    /**
      * filterexpr = mathexpr (FILTER callexpr)*
      */
    Node parseFilterExpr(string dirPath)
    {
        auto filterexpr = parseMathExpr( dirPath);

        while (front == Operator.Filter)
        {
            auto pos = front.pos;
            auto op = pop(Operator.Filter).value;
            filterexpr = new BinOpNode(pos, op, filterexpr, parseCallExpr( dirPath));
        }

        return filterexpr;
    }

    /**
      * Parse math expression:
      * mathexpr = term((PLUS|MINUS)term)*
      */
    Node parseMathExpr(string dirPath)
    {
        auto lhsTerm = parseTerm( dirPath);

        while (true)
        {
            if (front.type != Type.Operator)
                return lhsTerm;

            auto pos = front.pos;
            switch (front.value) with (Operator)
            {
                case Plus:
                case Minus:
                    auto op = pop.value;
                    lhsTerm = new BinOpNode(pos, op, lhsTerm, parseTerm( dirPath));
                    break;
                default:
                    return lhsTerm;
            }
        }
    }

    /**
      * Parse term:
      * term = unary((MUL|DIVI|DIVF|REM)unary)*
      */
    Node parseTerm(string dirPath)
    {
        auto lhsFactor = parseUnary( dirPath);

        while(true)
        {
            if (front.type != Type.Operator)
                return lhsFactor;

            auto pos = front.pos;
            switch (front.value) with (Operator)
            {
                case DivInt:
                case DivFloat:
                case Mul:
                case Rem:
                    auto op = pop.value;
                    lhsFactor = new BinOpNode(pos, op, lhsFactor, parseUnary( dirPath));
                    break;
                default:
                    return lhsFactor;
            }
        } 
    }

    /**
      * Parse unary:
      * unary = (pow | (PLUS|MINUS|NOT)unary)
      */
    Node parseUnary(string dirPath)
    {
        if (front.type != Type.Operator)
            return parsePow( dirPath);

        auto pos = front.pos;
        switch (front.value) with (Operator)
        {
            case Plus:
            case Minus:
            case Not:
                auto op = pop.value;
                return new UnaryOpNode(pos, op, parseUnary( dirPath));
            default:
                assertTemplate(0, "Unexpected operator `%s`".fmt(front.value), front.pos);
                assert(0);
        }
    }

    /**
      * Parse pow:
      * pow = factor (POW pow)?
      */
    Node parsePow(string dirPath)
    {
        auto lhs = parseFactor(dirPath);

        if (front.type == Type.Operator && front.value == Operator.Pow)
        {
            auto pos = front.pos;
            auto op = pop(Operator.Pow).value;
            return new BinOpNode(pos, op, lhs, parsePow( dirPath));
        }

        return lhs;
    }


    /**
      * Parse factor:
      * factor = (ident|(tuple|LPAREN HighLevelExpr RPAREN)|literal)
      */
    Node parseFactor(string dirPath)
    {
        switch (front.type) with (Type)
        {
            case Ident:
                return parseIdent( dirPath);

            case LParen:
                auto pos = front.pos;
                pop(LParen);
                bool hasCommas;
                auto exprList = parseSequenceOf!parseHighLevelExpression( dirPath,RParen, hasCommas);
                pop(RParen);
                return hasCommas ? new ListNode(pos, exprList) : exprList[0];

            default:
                return parseLiteral( dirPath);
        }
    }

    /**
      * Parse ident:
      * ident = IDENT (LPAREN ARGS RPAREN)? (DOT IDENT (LP ARGS RP)?| LSPAREN STR LRPAREN)*
      */
    Node parseIdent(string dirPath)
    {
        string name = "";
        Node[] subIdents = [];
        auto pos = front.pos;

        if (next.type == Type.LParen)
            subIdents ~= parseCallExpr( dirPath);
        else
            name = pop(Type.Ident).value;

        while (true)
        {
            switch (front.type) with (Type)
            {
                case Dot:
                    pop(Dot);
                    auto posStr = front.pos;
                    if (next.type == Type.LParen)
                        subIdents ~= parseCallExpr( dirPath);
                    else
                        subIdents ~= new StringNode(posStr, pop(Ident).value);
                    break;
                case LSParen:
                    pop(LSParen);
                    subIdents ~= parseHighLevelExpression( dirPath);
                    pop(RSParen);
                    break;
                default:
                    return new IdentNode(pos, name, subIdents);
            }
        }
    }


    IdentNode parseCallIdent(string dirPath)
    {
        auto pos = front.pos;
        return new IdentNode(pos, "", [parseCallExpr( dirPath)]);
    }


    DictNode parseCallExpr(string dirPath)
    {
        auto pos = front.pos;
        string name = pop(Type.Ident).value;
        Node[] varargs;
        Node[string] kwargs;

        bool parsingKwargs = false;
        void parse(string dirPath)
        {
            if (parsingKwargs || front.type == Type.Ident && next.value == Operator.Assign)
            {
                parsingKwargs = true;
                auto name = pop(Type.Ident).value;
                pop(Operator.Assign);
                kwargs[name] = parseHighLevelExpression( dirPath);
            }
            else
                varargs ~= parseHighLevelExpression( dirPath);
        }

        if (front.type == Type.LParen)
        {
            pop(Type.LParen);

            while (front.type != Type.EOF && front.type != Type.RParen)
            {
                parse( dirPath);

                if (front.type != Type.RParen)
                    pop(Type.Comma);
            }

            pop(Type.RParen);
        }

        Node[string] callDict;
        callDict["name"] = new StringNode(pos, name);
        callDict["varargs"] = new ListNode(pos, varargs);
        callDict["kwargs"] = new DictNode(pos, kwargs);

        return new DictNode(pos, callDict);
    }

    /**
      * literal = string|number|list|tuple|dict
      */
    Node parseLiteral(string dirPath)
    {
        auto pos = front.pos;
        switch (front.type) with (Type)
        {
            case Integer: return new NumNode(pos, pop.value.to!long);
            case Float:   return new NumNode(pos, pop.value.to!double);
            case String:  return new StringNode(pos, pop.value);
            case Boolean: return new BooleanNode(pos, pop.value.to!bool);
            case LParen:  return parseTuple( dirPath);
            case LSParen: return parseList( dirPath);
            case LBrace:  return parseDict( dirPath);
            default:
                assertTemplate(0, "Unexpected token while parsing expression: %s(%s)".fmt(front.type, front.value), front.pos);
                assert(0);
        }
    }


    Node parseTuple(string dirPath)
    {
        //Literally array right now

        auto pos = front.pos;
        pop(Type.LParen);
        auto tuple = parseSequenceOf!parseHighLevelExpression( dirPath,Type.RParen);
        pop(Type.RParen);

        return new ListNode(pos, tuple);
    }


    Node parseList(string dirPath)
    {
        auto pos = front.pos;
        pop(Type.LSParen);
        auto list = parseSequenceOf!parseHighLevelExpression( dirPath,Type.RSParen);
        pop(Type.RSParen);

        return new ListNode(pos, list);
    }


    Node[] parseSequenceOf(alias parser)(string dirPath,Type stopSymbol)
    {
        bool hasCommas;
        return parseSequenceOf!parser(dirPath,stopSymbol, hasCommas);
    }


    Node[] parseSequenceOf(alias parser)(string dirPath,Type stopSymbol, ref bool hasCommas)
    {
        Node[] seq;

        hasCommas = false;
        while (front.type != stopSymbol && front.type != Type.EOF)
        {
            seq ~= parser(dirPath);

            if (front.type != stopSymbol)
            {
                pop(Type.Comma);
                hasCommas = true;
            }
        }

        return seq;
    }


    Node parseDict(string dirPath)
    {
        Node[string] dict;
        auto pos = front.pos;

        pop(Type.LBrace);

        bool isFirst = true;
        while (front.type != Type.RBrace && front.type != Type.EOF)
        {
            if (!isFirst)
                pop(Type.Comma);

            string key;
            if (front.type == Type.Ident)
                key = pop(Type.Ident).value;
            else
                key = pop(Type.String).value;

            pop(Type.Colon);
            dict[key] = parseHighLevelExpression( dirPath);
            isFirst = false;
        }

        if (front.type == Type.Comma)
            pop(Type.Comma);

        pop(Type.RBrace);

        return new DictNode(pos, dict);
    }


    void parseComment(string dirPath)
    {
        pop(Type.CmntBegin);
        while (front.type != Type.CmntEnd && front.type != Type.EOF)
            pop();
        pop(Type.CmntEnd);
    }


    Token front()
    {
        if (_tokens.length)
            return _tokens[0];
        return Token.EOF;
    }

    Token next()
    {
        if (_tokens.length > 1)
            return _tokens[1];
        return Token.EOF;
    }


    Token pop()
    {
        auto tkn = front();
        if (_tokens.length)
            _tokens = _tokens[1 .. $];
        return tkn;
    }


    Token pop(Type t)
    {
        if (front.type != t)
            assertTemplate(0, "Unexpected token %s(%s), expected: `%s`".fmt(front.type, front.value, t), front.pos);
        return pop();
    }


    Token pop(Keyword kw)
    {
        if (front.type != Type.Keyword || front.value != kw)
            assertTemplate(0, "Unexpected token %s(%s), expected kw: %s".fmt(front.type, front.value, kw), front.pos);
        return pop();
    }


    Token pop(Operator op)
    {
        if (front.type != Type.Operator || front.value != op)
            assertTemplate(0, "Unexpected token %s(%s), expected op: %s".fmt(front.type, front.value, op), front.pos);
        return pop();
    }


    void pop(T...)(T args)
        if (args.length > 1)
    {
        foreach(arg; args)
            pop(arg);
    }


    void stashState()
    {
        ParserState old;
        old.tokens = _tokens;
        old.blocks = _blocks;
        _states ~= old;
        _tokens = [];
        _blocks = (BlockNode[string]).init;
    }


    void popState()
    {
        assertTemplate(_states.length > 0, "Unexpected empty state stack");

        auto state = _states.back;
        _states.popBack;
        _tokens = state.tokens;
        _blocks = state.blocks;
    }
}


private:


string absolute(string file,string path)
{
    //TODO
    // return path;
    import std.path : absolutePath;
    return (path ~ file);
}

bool fileExist(string file,string path)
{
    import std.path : absolutePath;
    version(HUNT_DEBUG) logDebug("path.absolutePath : ",(path ~ file).absolutePath);
    return (file.exists) || ((path ~ file).absolutePath.exists);
}

string stripOnceRight(string str)
{
    import std.uni;
    import std.utf : codeLength;

    import std.traits;
    alias C = Unqual!(ElementEncodingType!string);

    bool stripped = false;
    foreach_reverse (i, dchar c; str)
    {
        if (!isWhite(c))
            return str[0 .. i + codeLength!C(c)];

        if (c == '\n' || c == '\r' || c == 0x2028 || c == 0x2029)
        {
            return str[0 .. i];
        }
    }

    return str[0 .. 0];
}

unittest
{
    assert(stripOnceRight("\n") == "", stripOnceRight("\n"));
}
