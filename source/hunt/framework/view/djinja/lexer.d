/**
  * DJinja lexer
  *
  * Copyright:
  *     Copyright (c) 2018, Maxim Tyapkin.
  * Authors:
  *     Maxim Tyapkin
  * License:
  *     This software is licensed under the terms of the BSD 3-clause license.
  *     The full terms of the license can be found in the LICENSE.md file.
  */

module hunt.framework.view.djinja.lexer;


private
{
    import hunt.framework.view.djinja.exception : JinjaException;

    import std.conv : to;
    import std.traits : EnumMembers;
    import std.utf;
    import std.range;
}


enum Type
{
    Unknown,
    Raw,
    Keyword,
    Operator,
    
    StmtBegin,
    StmtEnd,
    ExprBegin,
    ExprEnd,
    CmntBegin,
    CmntEnd,
    CmntInline,

    Ident,
    Integer,
    Float,
    Boolean,
    String,

    LParen,
    RParen,
    LSParen,
    RSParen,
    LBrace,
    RBrace,

    Dot,
    Comma,
    Colon,

    EOL,
    EOF,
}


enum Keyword : string
{
    Unknown = "",
    For = "for",
    Recursive = "recursive",
    EndFor = "endfor",
    If = "if",
    ElIf = "elif",
    Else = "else",
    EndIf = "endif",
    Block = "block",
    EndBlock = "endblock",
    Extends = "extends",
    Macro = "macro",
    EndMacro = "endmacro",
    Return = "return",
    Call = "call",
    EndCall = "endcall",
    Filter = "filter",
    EndFilter = "endfilter",
    With = "with",
    EndWith = "endwith",
    Set = "set",
    EndSet = "endset",
    Ignore = "ignore",
    Missing = "missing",
    Import = "import",
    From = "from",
    As = "as",
    Without = "without",
    Context = "context",
    Include = "include",
}

bool isBeginingKeyword(Keyword kw)
{
    import std.algorithm : among;

    return cast(bool)kw.among(
                Keyword.If,
                Keyword.Set,
                Keyword.For,
                Keyword.Block,
                Keyword.Extends,
                Keyword.Macro,
                Keyword.Call,
                Keyword.Filter,
                Keyword.With,
                Keyword.Include,
                Keyword.Import,
                Keyword.From,
        );
}

Keyword toKeyword(string key)
{
    switch (key) with (Keyword)
    {
        static foreach(member; EnumMembers!Keyword)
        {
            case member:
                return member;
        }
        default :
            return Unknown;
    }
}


bool isKeyword(string key)
{
    return key.toKeyword != Keyword.Unknown;
}


bool isBoolean(string key)
{
    return key == "true" || key == "false" ||
           key == "True" || key == "False";
}


enum Operator : string
{
    // The first in order is the first in priority

    Eq = "==",
    NotEq = "!=",
    LessEq = "<=",
    GreaterEq = ">=",
    Less = "<",
    Greater = ">",

    And = "and",
    Or = "or",
    Not = "not",

    In = "in",
    Is = "is",

    Assign = "=",
    Filter = "|",
    Concat = "~",

    Plus = "+",
    Minus = "-",

    DivInt = "//",
    DivFloat = "/",
    Rem = "%",
    Pow = "**",
    Mul = "*",
}


Operator toOperator(string key)
{
    switch (key) with (Operator)
    {
        static foreach(member; EnumMembers!Operator)
        {
            case member:
                return member;
        }
        default :
            return cast(Operator)"";
    }
}

bool isOperator(string key)
{
    switch (key) with (Operator)
    {
        static foreach(member; EnumMembers!Operator)
        {
            case member:
        }
                return true;
        default :
            return false;
    }
}

bool isCmpOperator(Operator op)
{
    import std.algorithm : among;

    return cast(bool)op.among(
            Operator.Eq,
            Operator.NotEq,
            Operator.LessEq,
            Operator.GreaterEq,
            Operator.Less,
            Operator.Greater
        );
}


bool isIdentOperator(Operator op)()
{
    import std.algorithm : filter;
    import std.uni : isAlphaNum;

    static if (!(cast(string)op).filter!isAlphaNum.empty)
        return true;
    else
        return false;
}


struct Position
{
    string filename;
    ulong line, column;

    string toString()
    {
        return filename ~ "(" ~ line.to!string ~ "," ~ column.to!string ~ ")";
    }
}


struct Token
{
    enum EOF = Token(Type.EOF, Position("", 0, 0));

    Type type;
    string value;
    Position pos;

    this (Type t, Position p)
    {
        type = t;
        pos = p;
    }

    this(Type t, string v, Position p)
    {
        type = t;
        value = v;
        pos = p;
    }

    bool opEquals(Type type){
        return this.type == type;
    }

    bool opEquals(Keyword kw){
        return this.type == Type.Keyword && value == kw;
    }

    bool opEquals(Operator op){
        return this.type == Type.Operator && value == op;
    }
}


struct Lexer(
        string exprOpBegin, string exprOpEnd,
        string stmtOpBegin, string stmtOpEnd,
        string cmntOpBegin, string cmntOpEnd,
        string stmtOpInline, string cmntOpInline)
{
    static assert(exprOpBegin.length, "Expression begin operator can't be empty");
    static assert(exprOpEnd.length, "Expression end operator can't be empty");

    static assert(stmtOpBegin.length, "Statement begin operator can't be empty");
    static assert(stmtOpEnd.length, "Statement end operator can't be empty");

    static assert(cmntOpBegin.length, "Comment begin operator can't be empty");
    static assert(cmntOpEnd.length, "Comment end operator can't be empty");

    static assert(stmtOpInline.length, "Statement inline operator can't be empty");
    static assert(cmntOpInline.length, "Comment inline operator can't be empty");

    //TODO check uniq


    enum stmtInline = stmtOpInline;
    enum EOF = 255;

    private
    {
        Position _beginPos;
        bool _isReadingRaw; // State of reading raw data
        bool _isInlineStmt; // State of reading inline statement
        string _str;
        string _filename;
        ulong _line, _column;
    }

    this(string str, string filename = "")
    {
        _str = str;
        _isReadingRaw = true;
        _isInlineStmt = false;
        _filename = filename;
        _line = 1;
        _column = 1;
    }

    Token nextToken()
    {
        _beginPos = position();

        // Try to read raw data
        if (_isReadingRaw)
        {
            auto raw = skipRaw();
            _isReadingRaw = false;
            if (raw.length)
                return Token(Type.Raw, raw, _beginPos);
        }

        skipWhitespaces();
        _beginPos = position();

        // Check inline statement end
        if (_isInlineStmt &&
            (tryToSkipNewLine() || cmntOpInline == sliceOp!cmntOpInline))
        {
            _isInlineStmt = false;
            _isReadingRaw = true;
            return Token(Type.StmtEnd, "\n", _beginPos);
        }

        // Allow multiline inline statements with '\'
        while (true)
        {
            if (_isInlineStmt && front == '\\')
            {
                pop();
                if (!tryToSkipNewLine())
                    return Token(Type.Unknown, "\\", _beginPos);
            }
            else
                break;

            skipWhitespaces();
            _beginPos = position();
        }

        // Check begin operators
        if (exprOpBegin == sliceOp!exprOpBegin)
        {
            skipOp!exprOpBegin;
            return Token(Type.ExprBegin, exprOpBegin, _beginPos);
        }
        if (stmtOpBegin == sliceOp!stmtOpBegin)
        {
            skipOp!stmtOpBegin;
            return Token(Type.StmtBegin, stmtOpBegin, _beginPos);
        }
        if (cmntOpBegin == sliceOp!cmntOpBegin)
        {
            skipOp!cmntOpBegin;
            skipComment();
            return Token(Type.CmntBegin, cmntOpBegin, _beginPos);
        }

        // Check end operators
        if (exprOpEnd == sliceOp!exprOpEnd)
        {
            _isReadingRaw = true;
            skipOp!exprOpEnd;
            return Token(Type.ExprEnd, exprOpEnd, _beginPos);
        }
        if (stmtOpEnd == sliceOp!stmtOpEnd)
        {
            _isReadingRaw = true;
            skipOp!stmtOpEnd;
            return Token(Type.StmtEnd, stmtOpEnd, _beginPos);
        }
        if (cmntOpEnd == sliceOp!cmntOpEnd)
        {
            _isReadingRaw = true;
            skipOp!cmntOpEnd;
            return Token(Type.CmntEnd, cmntOpEnd, _beginPos);
        }

        // Check begin inline operators
        if (cmntOpInline == sliceOp!cmntOpInline)
        {
            skipInlineComment();
            _isReadingRaw = true;
            return Token(Type.CmntInline, cmntOpInline, _beginPos);
        }
        if (stmtOpInline == sliceOp!stmtOpInline)
        {
            skipOp!stmtOpInline;
            _isInlineStmt = true;
            return Token(Type.StmtBegin, stmtOpInline, _beginPos);
        }

        // Trying to read non-ident operators
        static foreach(op; EnumMembers!Operator)
        {
            static if (!isIdentOperator!op)
            {
                if (cast(string)op == sliceOp!op)
                {
                    skipOp!op;
                    return Token(Type.Operator, op, _beginPos);
                }
            }
        }

        // Check remainings 
        switch (front)
        {
            // End of file
            case EOF:
                return Token(Type.EOF, _beginPos);


            // Identifier or keyword
            case 'a': .. case 'z':
            case 'A': .. case 'Z':
            case '_':
                auto ident = popIdent();
                if (ident.toKeyword != Keyword.Unknown)
                    return Token(Type.Keyword, ident, _beginPos);
                else if (ident.isBoolean)
                    return Token(Type.Boolean, ident, _beginPos);
                else if (ident.isOperator)
                    return Token(Type.Operator, ident, _beginPos);
                else
                    return Token(Type.Ident, ident, _beginPos);

            // Integer or float
            case '0': .. case '9':
                return popNumber();

            // String
            case '"':
            case '\'':
                return Token(Type.String, popString(), _beginPos);
                
            case '(': return Token(Type.LParen, popChar, _beginPos);
            case ')': return Token(Type.RParen, popChar, _beginPos);
            case '[': return Token(Type.LSParen, popChar, _beginPos);
            case ']': return Token(Type.RSParen, popChar, _beginPos);
            case '{': return Token(Type.LBrace, popChar, _beginPos);
            case '}': return Token(Type.RBrace, popChar, _beginPos);
            case '.': return Token(Type.Dot, popChar, _beginPos);
            case ',': return Token(Type.Comma, popChar, _beginPos);
            case ':': return Token(Type.Colon, popChar, _beginPos);

            default:
                return Token(Type.Unknown, popChar, _beginPos);
        }
    }


private:


    dchar front()
    {
        if (_str.length > 0)
            return _str.front;
        else
            return EOF;
    }


    dchar next()
    {
        auto chars = _str.take(2).array;
        if (chars.length < 2)
            return EOF;
        return chars[1];
    }

    dchar pop()
    {
        if (_str.length > 0)
        {
            auto ch  = _str.front;

            if (ch.isNewLine && !(ch == '\r' && next == '\n'))
            {
                _line++;
                _column = 1;
            }
            else
                _column++;

            _str.popFront();
            return ch;
        } 
        else
            return EOF;
    }


    string popChar()
    {
        return pop.to!string;
    }


    string sliceOp(string op)()
    {
        enum length = op.walkLength;

        if (length >= _str.length)
            return _str;
        else
            return _str[0 .. length];
    }


    void skipOp(string op)()
    {
        enum length = op.walkLength;

        if (length >= _str.length)
            _str = "";
        else
            _str = _str[length .. $];
        _column += length;
    }


    Position position()
    {
        return Position(_filename, _line, _column);
    }


    void skipWhitespaces()
    {
        while (true)
        {
            if (front.isWhiteSpace)
            {
                pop();
                continue;
            }

            if (isFronNewLine)
            {
                // Return for handling NL as StmtEnd
                if (_isInlineStmt)
                    return;
                tryToSkipNewLine();
                continue;
            }

            return;
        }
    }


    string popIdent()
    {
        string ident = "";
        while (true)
        {
            switch(front)
            {
                case 'a': .. case 'z':
                case 'A': .. case 'Z':
                case '0': .. case '9':
                case '_':
                    ident ~= pop();
                    break;
                default:
                    return ident;
            }
        }
    }


    Token popNumber()
    {
        auto type = Type.Integer;
        string number = "";

        while (true)
        {
            switch (front)
            {
                case '0': .. case '9':
                    number ~= pop();
                    break;
                case '.':
                    if (type == Type.Integer)
                    {
                        type = Type.Float;
                        number ~= pop();
                    }
                    else
                        return Token(type, number, _beginPos);
                    break;
                case '_':
                    pop();
                    break;
                default:
                    return Token(type, number, _beginPos);
            }
        }
    }


    string popString()
    {
        auto ch = pop();
        string str = "";
        auto prev = ch;

        while (true)
        {
            if (front == EOF)
                return str;

            if (front == '\\')
            {
                pop();
                if (front != EOF)
                {
                    prev = pop();
                    switch (prev)
                    {
                        case 'n': str ~= '\n'; break;
                        case 'r': str ~= '\r'; break;
                        case 't': str ~= '\t'; break;
                        default: str ~= prev; break;
                    }
                }
                continue;
            }

            if (front == ch)
            {
                pop();
                return str;
            }

            prev = pop();
            str ~= prev;
        }
    }


    string skipRaw()
    {
        string raw = "";

        while (true)
        {
            if (front == EOF)
                return raw;

            if (exprOpBegin == sliceOp!exprOpBegin)
                return raw;
            if (stmtOpBegin == sliceOp!stmtOpBegin)
                return raw;
            if (cmntOpBegin == sliceOp!cmntOpBegin)
                return raw;
            if (stmtOpInline == sliceOp!stmtOpInline)
                return raw;
            if (cmntOpInline == sliceOp!cmntOpInline)
                return raw;
            
            raw ~= pop();
        }
    }


    void skipComment()
    {
        while(front != EOF)
        {
            if (cmntOpEnd == sliceOp!cmntOpEnd)
                return;
            pop();
        }
    }


    void skipInlineComment()
    {
        auto column = _column;

        while(front != EOF)
        {
            if (front == '\n')
            {
                // Eat new line if whole line is comment
                if (column == 1)
                    pop();
                return;
            }
            pop();
        }
    }


    bool isFronNewLine()
    {
        auto ch = front;
        return ch == '\r' || ch == '\n' || ch == 0x2028 || ch == 0x2029; 
    }

    /// true if NL was skiped
    bool tryToSkipNewLine()
    {
        switch (front)
        {
            case '\r':
                pop();
                if (front == '\n')
                    pop();
                return true;

            case '\n':
            case 0x2028:
            case 0x2029:
                pop();
                return true;

            default:
                return false;
        }
    }
}


bool isWhiteSpace(dchar ch)
{
    return ch == ' ' || ch == '\t' || ch == 0x205F || ch == 0x202F || ch == 0x3000
           || ch == 0x00A0 || (ch >= 0x2002 && ch <= 0x200B);
}

bool isNewLine(dchar ch)
{
    return ch == '\r' || ch == '\n' || ch == 0x2028 || ch == 0x2029;
}
