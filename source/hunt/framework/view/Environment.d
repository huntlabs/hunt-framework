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

module hunt.framework.view.Environment;

import std.string;
import std.json;
import std.file;
import std.path;
import std.stdio;

import hunt.logging;

import hunt.framework.application.AppConfig;
import hunt.framework.view.Template;
import hunt.framework.routing;

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

class Environment
{
    private 
    {
        string input_path;
        string output_path;

        alias JinjaLexer = Lexer!(TemplateConfig.init.exprOpBegin,
                TemplateConfig.init.exprOpEnd, TemplateConfig.init.stmtOpBegin, TemplateConfig.init.stmtOpEnd,
                TemplateConfig.init.cmntOpBegin, TemplateConfig.init.cmntOpEnd, TemplateConfig.init.stmtOpInline, TemplateConfig.init.cmntOpInline);
        Parser!JinjaLexer _parser;

        string _routeGroup = DEFAULT_ROUTE_GROUP;
        string _locale = "en-us";
    }

public:
    this()
    {
        auto tpl_path = Config.app.view.path;
        if (tpl_path.length == 0)
            tpl_path = "./views/";
        input_path = output_path = buildNormalizedPath(tpl_path) ~ dirSeparator;
    }

    this(string global_path)
    {
        input_path = output_path = buildNormalizedPath(global_path) ~ dirSeparator;
    }

    this(string input_path, string output_path)
    {
        this.input_path = buildNormalizedPath(input_path) ~ dirSeparator;
        this.output_path = buildNormalizedPath(output_path) ~ dirSeparator;
    }

    void setRouteGroup(string rg)
    {
        _routeGroup = rg;
    }

    void setLocale(string locale)
    {
        _locale = locale;
    }

    void setTemplatePath(string path)
    {
        this.input_path = buildNormalizedPath(path) ~ dirSeparator;
    }

    TemplateNode parse_template(string filename)
    {
        version (HUNT_DEBUG)
            trace("parse file path : ", input_path ~ filename);
        // _parser.setPath(input_path);
        return _parser.parseTreeFromFile(input_path ~ filename);
    }

    string render(TemplateNode tree,JSONValue data)
    {
        import hunt.framework.util.uninode.Serialization;

        auto render = new Render(tree);
        render.setRouteGroup(_routeGroup);
        render.setLocale(_locale);
        return render.render(jsonToUniNode(data));
    }

    string renderFile(string path,JSONValue data)
    {
         return render(parse_template(path),data);
    }

    string render(string str,JSONValue data)
    {
        import hunt.framework.util.uninode.Serialization;
        auto tree = _parser.parseTree(str,"",input_path);
        auto render = new Render(tree);
        render.setRouteGroup(_routeGroup);
        render.setLocale(_locale);
        return render.render(jsonToUniNode(data));
    } 
};
