/**
  * D implementation of Jinja2 templates
  *
  * Copyright:
  *     Copyright (c) 2018, Maxim Tyapkin.
  * Authors:
  *     Maxim Tyapkin
  * License:
  *     This software is licensed under the terms of the BSD 3-clause license.
  *     The full terms of the license can be found in the LICENSE.md file.
  */

module hunt.framework.view.djinja.djinja;

private
{
    import std.meta;
    import std.traits;

    import hunt.framework.view.djinja.render;
    import hunt.framework.view.djinja.lexer;
    import hunt.framework.view.djinja.parser;
    import hunt.framework.view.djinja.uninode;
    import hunt.framework.view.djinja.ast;
}



struct JinjaConfig
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



TemplateNode loadData(JinjaConfig config = defaultConfig)(string tmpl)
{
    alias JinjaLexer = Lexer!(
                            config.exprOpBegin,
                            config.exprOpEnd,
                            config.stmtOpBegin,
                            config.stmtOpEnd,
                            config.cmntOpBegin,
                            config.cmntOpEnd,
                            config.stmtOpInline,
                            config.cmntOpInline
                        );

    Parser!JinjaLexer parser;
    return parser.parseTree(tmpl);
}



TemplateNode loadFile(JinjaConfig config = defaultConfig)(string path)
{
    alias JinjaLexer = Lexer!(
                            config.exprOpBegin,
                            config.exprOpEnd,
                            config.stmtOpBegin,
                            config.stmtOpEnd,
                            config.cmntOpBegin,
                            config.cmntOpEnd,
                            config.stmtOpInline,
                            config.cmntOpInline
                        );

    Parser!JinjaLexer parser;
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
    static if (T.length > 0 && is(typeof(T[0]) == JinjaConfig))
        return render!(T[1 .. $])(loadData!(T[0])(tmpl));
    else
        return render!(T)(loadData!defaultConfig(tmpl));
}



string renderFile(T...)(string path)
{
    static if (T.length > 0 && is(typeof(T[0]) == JinjaConfig))
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



enum defaultConfig = JinjaConfig.init;



template Ident(alias A)
{
    enum Ident = __traits(identifier, A);
}
