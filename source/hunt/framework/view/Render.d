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

module hunt.framework.view.Render;

private
{
    import std.range;
    import std.format: fmt = format;

    import hunt.framework.view.ast.Node;
    import hunt.framework.view.ast.Visitor;
    import hunt.framework.view.algo;
    import hunt.framework.view.algo.Wrapper;
    import hunt.framework.view.Lexer;
    import hunt.framework.view.Parser;
    import hunt.framework.view.Exception : TemplateRenderException,
                              assertTemplate = assertTemplateRender;

    import hunt.framework.view.Uninode;

    import hunt.framework.Simplify;
    import hunt.framework.view.Util;
    import hunt.logging;
}




struct FormArg
{
    string name;
    Nullable!UniNode def;

    this (string name)
    {
        this.name = name;
        this.def = Nullable!UniNode.init;
    }

    this (string name, UniNode def)
    {
        this.name = name;
        this.def = Nullable!UniNode(def);
    }
}


struct Macro
{
    FormArg[] args;
    Nullable!Context context;
    Nullable!Node block;

    this(FormArg[] args, Context context, Node block)
    {
        this.args = args;
        this.context = context.toNullable;
        this.block = block.toNullable;
    }
}


class Context
{
    private Context prev;

    UniNode data;
    Function[string] functions;
    Macro[string] macros;

    this ()
    {
        prev = null;
        data = UniNode.emptyObject();
    }

    this (Context ctx, UniNode data)
    {
        prev = ctx;
        this.data = data;
    }

    Context previos() @property
    {
        if (prev !is null)
            return prev;
        return this;
    }

    bool has(string name)
    {
        if (name in data)
            return true;
        if (prev is null)
            return false;
        return prev.has(name);
    }

    UniNode get(string name)
    {
        if (name in data)
            return data[name];
        if (prev is null)
            return UniNode(null);
        return prev.get(name);
    }

    UniNode* getPtr(string name)
    {
        if (name in data)
            return &(data[name]);
        if (prev is null)
            assertTemplate(0, "Non declared var `%s`".fmt(name));
        return prev.getPtr(name);
    }

    T get(T)(string name)
    {
        return this.get(name).get!T;
    }

    bool hasFunc(string name)
    {
        if (name in functions)
            return true;
        if (prev is null)
            return false;
        return prev.hasFunc(name);
    }


    Function getFunc(string name)
    {
        if (name in functions)
            return functions[name];
        if (prev is null)
            assertTemplate(0, "Non declared function `%s`".fmt(name));
        return prev.getFunc(name);
    }


    bool hasMacro(string name)
    {
        if (name in macros)
            return true;
        if (prev is null)
            return false;
        return prev.hasMacro(name);
    }


    Macro getMacro(string name)
    {
        if (name in macros)
            return macros[name];
        if (prev is null)
            assertTemplate(0, "Non declared macro `%s`".fmt(name));
        return prev.getMacro(name);
    }
}


struct AppliedFilter
{
    string name;
    UniNode args;
}


class Render : VisitorInterface
{
    private
    {
        TemplateNode    _root;
        Context         _globalContext;
        Context         _rootContext;
        UniNode[]       _dataStack;
        AppliedFilter[] _appliedFilters;
        TemplateNode[]  _extends;

        Context         _context;

        string          _renderedResult;
        bool            _isExtended;

        string _routeGroup = DEFAULT_ROUTE_GROUP;
        string _locale = "en-us";
    }

    this(TemplateNode root)
    {
        _root = root;
        _rootContext = new Context();

        foreach(key, value; globalFunctions)
            _rootContext.functions[key] = cast(Function)value;
        foreach(key, value; globalFilters)
            _rootContext.functions[key] = cast(Function)value;
        foreach(key, value; globalTests)
            _rootContext.functions[key] = cast(Function)value;
    }

    public void setRouteGroup(string rg)
    {
        _routeGroup = rg;
    }

    public void setLocale(string locale)
    {
        _locale = locale;
    }

    string render(UniNode data)
    {
        import hunt.logging;
        version(HUNT_VIEW_DEBUG) logDebug("----render data : ", data);
        _context = new Context(_rootContext, data);
        _globalContext = _context;

        _extends = [_root];
        _isExtended = false;

        _renderedResult = "";
        if (_root !is null)
            tryAccept(_root);
        return _renderedResult;
    }


    override void visit(TemplateNode node)
    {
        tryAccept(node.stmt.get);
    }

    override void visit(BlockNode node)
    {
        void super_()
        {
            tryAccept(node.stmt.get);
        }

        foreach (tmpl; _extends[0 .. $-1])
            if (node.name in tmpl.blocks)
            {
                pushNewContext();
                _context.functions["super"] = wrapper!super_;
                tryAccept(tmpl.blocks[node.name].stmt.get);
                popContext();
                return;
            }

        super_();
    }


    override void visit(StmtBlockNode node)
    {
        pushNewContext();
        foreach(ch; node.children)
            tryAccept(ch);
        popContext();
    }

    override void visit(RawNode node)
    {
        writeToResult(node.raw);
    }

    override void visit(ExprNode node)
    {
        tryAccept(node.expr.get);
        auto n = pop();
        n.toStringType;
        writeToResult(n.get!string);
    }

    override void visit(InlineIfNode node)
    {
        bool condition = true;

        if (!node.cond.isNull)
        {
            tryAccept(node.cond.get);
            auto res = pop();
            res.toBoolType;
            condition = res.get!bool;
        }

        if (condition)
        {
            tryAccept(node.expr.get);
        }
        else if (!node.other.isNull)
        {
            tryAccept(node.other.get);
        }
        else
        {
            push(UniNode(null));
        }
    }

    override void visit(BinOpNode node)
    {
        UniNode calc(Operator op)()
        {
            tryAccept(node.lhs);
            auto lhs = pop();

            tryAccept(node.rhs);
            auto rhs = pop();

            return binary!op(lhs, rhs);
        }

        UniNode calcLogic(bool stopCondition)()
        {
            tryAccept(node.lhs);
            auto lhs = pop();
            lhs.toBoolType;
            if (lhs.get!bool == stopCondition)
                return UniNode(stopCondition);

            tryAccept(node.rhs);
            auto rhs = pop();
            rhs.toBoolType;
            return UniNode(rhs.get!bool);
        }

        UniNode calcCall(string type)()
        {
            tryAccept(node.lhs);
            auto lhs = pop();

            tryAccept(node.rhs);
            auto args = pop();
            auto name = args["name"].get!string;
            args["varargs"] = UniNode([lhs] ~ args["varargs"].get!(UniNode[]));

            if (_context.hasFunc(name))
                return visitFunc(name, args);
            else if (_context.hasMacro(name))
                return visitMacro(name, args);
            else
                assertTemplate(0, "Undefined " ~ type ~ " %s".fmt(name), node.pos);
            assert(0);
        }

        UniNode calcFilter()
        {
            return calcCall!"filter";
        }

        UniNode calcIs()
        {
            auto res = calcCall!"test";
            res.toBoolType;
            return res;
        }

        UniNode doSwitch()
        {
            switch (node.op) with (Operator)
            {
                case Concat:    return calc!Concat;
                case Plus:      return calc!Plus;
                case Minus:     return calc!Minus;
                case DivInt:    return calc!DivInt;
                case DivFloat:  return calc!DivFloat;
                case Rem:       return calc!Rem;
                case Mul:       return calc!Mul;
                case Greater:   return calc!Greater;
                case Less:      return calc!Less;
                case GreaterEq: return calc!GreaterEq;
                case LessEq:    return calc!LessEq;
                case Eq:        return calc!Eq;
                case NotEq:     return calc!NotEq;
                case Pow:       return calc!Pow;
                case In:        return calc!In;

                case Or:        return calcLogic!true;
                case And:       return calcLogic!false;

                case Filter:    return calcFilter;
                case Is:        return calcIs;

                default:
                    assert(0, "Not implemented binary operator");
            }
        }

        push(doSwitch());
    }

    override void visit(UnaryOpNode node)
    {
        tryAccept(node.expr);
        auto res = pop();
        UniNode doSwitch()
        {
            switch (node.op) with (Operator)
            {
                case Plus:      return unary!Plus(res);
                case Minus:     return unary!Minus(res);
                case Not:       return unary!Not(res);
                default:
                    assert(0, "Not implemented unary operator");
            }
        }

        push(doSwitch());
    }

    override void visit(NumNode node)
    {
        if (node.type == NumNode.Type.Integer)
            push(UniNode(node.data._integer));
        else
            push(UniNode(node.data._float));
    }

    override void visit(BooleanNode node)
    {
        push(UniNode(node.boolean));
    }

    override void visit(NilNode node)
    {
        push(UniNode(null));
    }

    override void visit(IdentNode node)
    {
        UniNode curr;
        if (node.name.length)
            curr = _context.get(node.name);
        else
            curr = UniNode(null);

        auto lastPos = node.pos;
        foreach (sub; node.subIdents)
        {
            tryAccept(sub);
            auto key = pop();

            switch (key.kind) with (UniNode.Kind)
            {
                // Index of list/tuple
                case integer:
                case uinteger:
                    curr.checkNodeType(array, lastPos);
                    if (key.get!size_t < curr.length)
                        curr = curr[key.get!size_t];
                    else
                        assertTemplate(0, "Range violation  on %s...[%d]".fmt(node.name, key.get!size_t), sub.pos);
                    break;

                // Key of dict
                case text:
                    auto keyStr = key.get!string;
                    if (curr.kind == UniNode.Kind.object && keyStr in curr)
                        curr = curr[keyStr];
                    else if (_context.hasFunc(keyStr))
                    {
                        auto args = [
                            "name": UniNode(keyStr),
                            "varargs": UniNode([curr]),
                            "kwargs": UniNode.emptyObject
                        ];
                        curr = visitFunc(keyStr, UniNode(args));
                    }
                    else if (_context.hasMacro(keyStr))
                    {
                        auto args = [
                            "name": UniNode(keyStr),
                            "varargs": UniNode([curr]),
                            "kwargs": UniNode.emptyObject
                        ];
                        curr = visitMacro(keyStr, UniNode(args));
                    }
                    else
                    {
                        curr.checkNodeType(object, lastPos);
                        assertTemplate(0, "Unknown attribute %s".fmt(key.get!string), sub.pos);
                    }
                    break;

                // Call of function
                case object:
                    auto name = key["name"].get!string;

                    if (!curr.isNull)
                        key["varargs"] = UniNode([curr] ~ key["varargs"].get!(UniNode[]));

                    if (_context.hasFunc(name))
                    {
                        curr = visitFunc(name, key);
                    }
                    else if (_context.hasMacro(name))
                    {
                        curr = visitMacro(name, key);
                    }
                    else
                        assertTemplate(0, "Not found any macro, function or filter `%s`".fmt(name), sub.pos);
                    break;

                default:
                    assertTemplate(0, "Unknown attribute %s for %s".fmt(key.toString, node.name), sub.pos);
            }

            lastPos = sub.pos;
        }

        push(curr);
    }

    override void visit(AssignableNode node)
    {
        auto expr = pop();

        // TODO: check flag of set scope
        if (!_context.has(node.name))
        {
            if (node.subIdents.length)
                assertTemplate(0, "Unknow variable %s".fmt(node.name), node.pos);
            _context.data[node.name] = expr;
            return;
        }

        UniNode* curr = _context.getPtr(node.name);

        if (!node.subIdents.length)
        {
            (*curr) = expr;
            return;
        }

        auto lastPos = node.pos;
        for(int i = 0; i < cast(int)(node.subIdents.length) - 1; i++)
        {
            tryAccept(node.subIdents[i]);
            auto key = pop();

            switch (key.kind) with (UniNode.Kind)
            {
                // Index of list/tuple
                case integer:
                case uinteger:
                    checkNodeType(*curr, array, lastPos);
                    if (key.get!size_t < curr.length)
                        curr = &((*curr)[key.get!size_t]);
                    else
                        assertTemplate(0, "Range violation  on %s...[%d]".fmt(node.name, key.get!size_t), node.subIdents[i].pos);
                    break;

                // Key of dict
                case text:
                    checkNodeType(*curr, object, lastPos);
                    if (key.get!string in *curr)
                        curr = &((*curr)[key.get!string]);
                    else
                        assertTemplate(0, "Unknown attribute %s".fmt(key.get!string), node.subIdents[i].pos);
                    break;

                default:
                    assertTemplate(0, "Unknown attribute %s for %s".fmt(key.toString, node.name), node.subIdents[i].pos);
            }
            lastPos = node.subIdents[i].pos;
        }

        if (node.subIdents.length)
        {
            tryAccept(node.subIdents[$-1]);
            auto key = pop();

            switch (key.kind) with (UniNode.Kind)
            {
                // Index of list/tuple
                case integer:
                case uinteger:
                    checkNodeType(*curr, array, lastPos);
                    if (key.get!size_t < curr.length)
                        (*curr).opIndex(key.get!size_t) = expr; // ¯\_(ツ)_/¯
                    else
                        assertTemplate(0, "Range violation  on %s...[%d]".fmt(node.name, key.get!size_t), node.subIdents[$-1].pos);
                    break;

                // Key of dict
                case text:
                    checkNodeType(*curr, object, lastPos);
                    (*curr)[key.get!string] = expr;
                    break;

                default:
                    assertTemplate(0, "Unknown attribute %s for %s".fmt(key.toString, node.name, node.subIdents[$-1].pos));
            }
        }
    }

    override void visit(StringNode node)
    {
        push(UniNode(node.str));
    }

    override void visit(ListNode node)
    {
        UniNode[] list = [];
        foreach (l; node.list)
        {
            tryAccept(l);
            list ~= pop();
        }
        push(UniNode(list));
    }

    override void visit(DictNode node)
    {
        UniNode[string] dict;
        foreach (key, value; node.dict)
        {
            tryAccept(value);
            dict[key] = pop();
        }
        push(UniNode(dict));
    }

    override void visit(IfNode node)
    {
        tryAccept(node.cond);

        auto cond = pop();
        cond.toBoolType;

        if (cond.get!bool)
        {
            tryAccept(node.then);
        }
        else if (node.other)
        {
            tryAccept(node.other);
        }
    }

    override void visit(ForNode node)
    {
        bool iterated = false;
        int depth = 0;
        bool calcCondition()
        {
            bool condition = true;
            if (!node.cond.isNull)
            {
                tryAccept(node.cond.get);
                auto cond = pop();
                cond.toBoolType;
                condition = cond.get!bool;
            }
            return condition;
        }

        UniNode cycle(UniNode loop, UniNode varargs)
        {
            if (!varargs.length)
                return UniNode(null);
            return varargs[loop["index0"].get!size_t % varargs.length];
        }


        void loop(UniNode iterable)
        {
            Nullable!UniNode lastVal;
            bool changed(UniNode loop, UniNode val)
            {
                if (!lastVal.isNull && val == lastVal.get)
                    return false;
                lastVal = val;
                return true;
            }

            depth++;
            pushNewContext();

            iterable.toIterableNode;

            if (!node.cond.isNull)
            {
                auto newIterable = UniNode.emptyArray;
                for (int i = 0; i < iterable.length; i++)
                {
                    if (node.keys.length == 1)
                        _context.data[node.keys[0]] = iterable[i];
                    else
                    {
                        iterable[i].checkNodeType(UniNode.Kind.array, node.iterable.get.pos);
                        assertTemplate(iterable[i].length >= node.keys.length, "Num of keys less then values", node.iterable.get.pos);
                        foreach(j, key; node.keys)
                            _context.data[key] = iterable[i][j];
                    }

                    if (calcCondition())
                        newIterable ~= iterable[i];
                }
                iterable = newIterable;
            }

            _context.data["loop"] = UniNode.emptyObject;
            _context.data["loop"]["length"] = UniNode(iterable.length);
            _context.data["loop"]["depth"] = UniNode(depth);
            _context.data["loop"]["depth0"] = UniNode(depth - 1);
            _context.functions["cycle"] = wrapper!cycle;
            _context.functions["changed"] = wrapper!changed;

            for (int i = 0; i < iterable.length; i++)
            {
                _context.data["loop"]["index"] = UniNode(i + 1);
                _context.data["loop"]["index0"] = UniNode(i);
                _context.data["loop"]["revindex"] = UniNode(iterable.length - i);
                _context.data["loop"]["revindex0"] = UniNode(iterable.length - i - 1);
                _context.data["loop"]["first"] = UniNode(i == 0);
                _context.data["loop"]["last"] = UniNode(i == iterable.length - 1);
                _context.data["loop"]["previtem"] = i > 0 ? iterable[i - 1] : UniNode(null);
                _context.data["loop"]["nextitem"] = i < iterable.length - 1 ? iterable[i + 1] : UniNode(null);

                if (node.isRecursive)
                    _context.functions["loop"] = wrapper!loop;

                if (node.keys.length == 1)
                    _context.data[node.keys[0]] = iterable[i];
                else
                {
                    iterable[i].checkNodeType(UniNode.Kind.array, node.iterable.get.pos);
                    assertTemplate(iterable[i].length >= node.keys.length, "Num of keys less then values", node.iterable.get.pos);
                    foreach(j, key; node.keys)
                        _context.data[key] = iterable[i][j];
                }

                tryAccept(node.block.get);
                iterated = true;
            }
            popContext();
            depth--;
        }



        tryAccept(node.iterable.get);
        UniNode iterable = pop();
        loop(iterable);

        if (!iterated && !node.other.isNull)
            tryAccept(node.other.get);
    }


    override void visit(SetNode node)
    {
        tryAccept(node.expr);

        if (node.assigns.length == 1)
            tryAccept(node.assigns[0]);
        else
        {
            auto expr = pop();
            expr.checkNodeType(UniNode.Kind.array, node.expr.pos);

            if (expr.length < node.assigns.length)
                assertTemplate(0, "Iterable length less then number of assigns", node.expr.pos);

            foreach(idx, assign; node.assigns)
            {
                push(expr[idx]);
                tryAccept(assign);
            }
        }
    }


    override void visit(MacroNode node)
    {
        FormArg[] args;

        foreach(arg; node.args)
        {
            if (arg.defaultExpr.isNull)
                args ~= FormArg(arg.name);
            else
            {
                tryAccept(arg.defaultExpr.get);
                args ~= FormArg(arg.name, pop());
            }
        }

        _context.macros[node.name] = Macro(args, _context, node.block.get);
    }


    override void visit(CallNode node)
    {
        FormArg[] args;

        foreach(arg; node.formArgs)
        {
            if (arg.defaultExpr.isNull)
                args ~= FormArg(arg.name);
            else
            {
                tryAccept(arg.defaultExpr.get);
                args ~= FormArg(arg.name, pop());
            }
        }

        auto caller = Macro(args, _context, node.block.get);

        tryAccept(node.factArgs.get);
        auto factArgs = pop();

        visitMacro(node.macroName, factArgs, caller.nullable);
    }


    override void visit(FilterBlockNode node)
    {
        tryAccept(node.args.get);
        auto args = pop();

        pushFilter(node.filterName, args);
        tryAccept(node.block.get);
        popFilter();
    }


    override void visit(ImportNode node)
    {
        if (node.tmplBlock.isNull)
            return;

        auto stashedContext = _context;
        auto stashedResult = _renderedResult;

        if (!node.withContext)
            _context = _globalContext;

        _renderedResult = "";

        pushNewContext();

        foreach (child; node.tmplBlock.get.stmt.get.children)
            tryAccept(child);

        auto macros = _context.macros;

        popContext();

        _renderedResult = stashedResult;

        if (!node.withContext)
            _context = stashedContext;

        if (node.macrosNames.length)
            foreach (name; node.macrosNames)
            {
                assertTemplate(cast(bool)(name.was in macros), "Undefined macro `%s` in `%s`".fmt(name.was, node.fileName), node.pos);
                _context.macros[name.become] = macros[name.was];
            }
        else
            foreach (key, val; macros)
                _context.macros[key] = val;
    }


    override void visit(IncludeNode node)
    {
        if (node.tmplBlock.isNull)
            return;

        auto stashedContext = _context;

        if (!node.withContext)
            _context = _globalContext;

        tryAccept(node.tmplBlock.get);

        if (!node.withContext)
            _context = stashedContext;
    }


    override void visit(ExtendsNode node)
    {
        _extends ~= node.tmplBlock;
        tryAccept(node.tmplBlock.get);
        _extends.popBack;
        _isExtended = true;
    }

    private void tryAccept(Node node)
    {
        if (!_isExtended)
            node.accept(this);
    }


    private UniNode visitFunc(string name, UniNode args)
    {
        version(HUNT_VIEW_DEBUG) logDebug("---Func :",name," args: ",args);

        if(name == "trans")
        {
            if("varargs" in args)
            {
                return doTrans(args["varargs"]);
            }
        }
        else if(name == "date")
        {
            import hunt.util.DateTime;
            auto format = args["varargs"][0].get!string;
            auto timestamp = args["varargs"][1].get!int;
            return UniNode(date(format, timestamp));
        }
        else if(name == "url")
        {
            import hunt.framework.Simplify : url;

            auto mca = args["varargs"][0].get!string;
            auto params = args["varargs"][1].get!string;
            return UniNode(url(mca, Util.parseFormData(params), _routeGroup));
        }
        return _context.getFunc(name)(args);
    }

    private UniNode doTrans(UniNode arg)
    {
        import hunt.framework.i18n;
        import hunt.framework.util.uninode.Serialization;

        if(arg.kind == UniNode.Kind.array)
        {
            if(arg.length == 1)
            {
                return UniNode(transWithLocale(_locale,arg[0].get!string));
            }
            else if(arg.length > 1)
            {
                string msg = arg[0].get!string;
                UniNode[] args;
                for(int i=1; i < arg.length ; i++)
                {
                     args ~= arg[i];
                }
                
                return UniNode(transWithLocale(_locale,msg,uniNodeToJSON(UniNode(args))));
            }
        }
        throw new TemplateRenderException("unsupport param : " ~ arg.toString);
    }


    private UniNode visitMacro(string name, UniNode args, Nullable!Macro caller = Nullable!Macro.init)
    {
        UniNode result;

        auto macro_ = _context.getMacro(name);
        auto stashedContext = _context;
        _context = macro_.context.get;
        pushNewContext();

        UniNode[] varargs;
        UniNode[string] kwargs;

        foreach(arg; macro_.args)
            if (!arg.def.isNull)
                _context.data[arg.name] = arg.def.get;

        for(int i = 0; i < args["varargs"].length; i++)
        {
            if (i < macro_.args.length)
                _context.data[macro_.args[i].name] = args["varargs"][i];
            else
                varargs ~= args["varargs"][i];
        }

        foreach (string key, value; args["kwargs"])
        {
            if (macro_.args.has(key))
                _context.data[key] = value;
            else
                kwargs[key] = value;
        }

        _context.data["varargs"] = UniNode(varargs);
        _context.data["kwargs"] = UniNode(kwargs);

        foreach(arg; macro_.args)
            if (arg.name !in _context.data)
                assertTemplate(0, "Missing value for argument `%s` in macro `%s`".fmt(arg.name, name));

        if (!caller.isNull)
            _context.macros["caller"] = caller;

        tryAccept(macro_.block.get);
        result = pop();

        popContext();
        _context = stashedContext;

        return result;
    }

    private void writeToResult(string str)
    {
        if (!_appliedFilters.length)
        {
            _renderedResult ~= str;
        }
        else
        {
            UniNode curr = UniNode(str);
            foreach_reverse (filter; _appliedFilters)
            {
                auto args = filter.args;
                args["varargs"] = UniNode([curr] ~ args["varargs"].get!(UniNode[]));

                if (_context.hasFunc(filter.name))
                    curr = visitFunc(filter.name, args);
                else if (_context.hasMacro(filter.name))
                    curr = visitMacro(filter.name, args);
                else
                    assert(0);

                curr.toStringType;
            }

            _renderedResult ~= curr.get!string;
        }
    }

    private void pushNewContext()
    {
        _context = new Context(_context, UniNode.emptyObject);
    }


    private void popContext()
    {
        _context = _context.previos;
    }


    private void push(UniNode un)
    {
        _dataStack ~= un;
    }


    private UniNode pop()
    {
        if (!_dataStack.length)
            assertTemplate(0, "Unexpected empty stack");

        auto un = _dataStack.back;
        _dataStack.popBack;
        return un;
    }


    private void pushFilter(string name, UniNode args)
    {
        _appliedFilters ~= AppliedFilter(name, args);
    }


    private void popFilter()
    {
        if (!_appliedFilters.length)
            assertTemplate(0, "Unexpected empty filter stack");

        _appliedFilters.popBack;
    }
}


void registerFunction(alias func)(Render render, string name)
{
    render._rootContext.functions[name] = wrapper!func;
}


void registerFunction(alias func)(Render render)
{
    enum name = __traits(identifier, func);
    render._rootContext.functions[name] = wrapper!func;
}


private bool has(FormArg[] arr, string name)
{
    foreach(a; arr)
        if (a.name == name)
            return true;
    return false;
}
