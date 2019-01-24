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

module hunt.framework.view.Template;

private
{
    import std.meta;
    import std.traits;

    import hunt.framework.view.Render;
    import hunt.framework.view.Lexer;
    import hunt.framework.view.Parser;
    import hunt.framework.view.Uninode;
    import hunt.framework.view.ast;
}

struct TemplateConfig
{
    string exprOpBegin  = "{{";
    string exprOpEnd    = "}}";
    string stmtOpBegin  = "{%";
    string stmtOpEnd    = "%}";
    string cmntOpBegin  = "{#";
    string cmntOpEnd    = "#}";
    string cmntOpInline = "##!";
    string stmtOpInline = "#!";
}

TemplateNode loadData(TemplateConfig config = defaultConfig)(string tmpl)
{
    alias TemplateLexer = Lexer!(
                            config.exprOpBegin,
                            config.exprOpEnd,
                            config.stmtOpBegin,
                            config.stmtOpEnd,
                            config.cmntOpBegin,
                            config.cmntOpEnd,
                            config.stmtOpInline,
                            config.cmntOpInline
                        );

    Parser!TemplateLexer parser;
    return parser.parseTree(tmpl);
}

TemplateNode loadFile(TemplateConfig config = defaultConfig)(string path)
{
    alias TemplateLexer = Lexer!(
                            config.exprOpBegin,
                            config.exprOpEnd,
                            config.stmtOpBegin,
                            config.stmtOpEnd,
                            config.cmntOpBegin,
                            config.cmntOpEnd,
                            config.stmtOpInline,
                            config.cmntOpInline
                        );

    Parser!TemplateLexer parser;
    return parser.parseTreeFromFile(path);
}

string render(T...)(TemplateNode tree)
{
    alias Args = AliasSeq!T;
    alias Idents = staticMap!(Ident, T);

    auto render = new Render(tree);

    auto data = UniNode.emptyObject();

    foreach (i, arg; Args)
    {
        static if (isSomeFunction!arg)
            render.registerFunction!arg(Idents[i]);
        else
            data[Idents[i]] = arg.serialize;
    }

    return render.render(data.serialize);
}

string renderData(T...)(string tmpl)
{
    static if (T.length > 0 && is(typeof(T[0]) == TemplateConfig))
        return render!(T[1 .. $])(loadData!(T[0])(tmpl));
    else
        return render!(T)(loadData!defaultConfig(tmpl));
}

string renderFile(T...)(string path)
{
    static if (T.length > 0 && is(typeof(T[0]) == TemplateConfig))
        return render!(T[1 .. $])(loadFile!(T[0])(path));
    else
        return render!(T)(loadFile!defaultConfig(path));
}



void print(TemplateNode tree)
{
    auto printer = new Printer;
    tree.accept(printer);
}

private:

enum defaultConfig = TemplateConfig.init;

template Ident(alias A)
{
    enum Ident = __traits(identifier, A);
}
