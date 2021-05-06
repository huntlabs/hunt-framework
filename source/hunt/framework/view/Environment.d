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

import hunt.framework.Simplify;
import hunt.framework.view.Template;
import hunt.framework.view.Render;
import hunt.framework.view.Lexer;
import hunt.framework.view.Parser;
import hunt.framework.view.Uninode;
import hunt.framework.view.ast;
import hunt.framework.util.uninode.Serialization;

import hunt.framework.http.Request;
import hunt.framework.Init;

import hunt.logging.ConsoleLogger;

import std.meta;
import std.traits;
import std.string;
import std.json;
import std.file;
import std.path;
import std.stdio;


class Environment
{
    alias TemplateLexer = Lexer!(TemplateConfig.init.exprOpBegin,
            TemplateConfig.init.exprOpEnd, TemplateConfig.init.stmtOpBegin, TemplateConfig.init.stmtOpEnd,
            TemplateConfig.init.cmntOpBegin, TemplateConfig.init.cmntOpEnd, TemplateConfig.init.stmtOpInline, 
            TemplateConfig.init.cmntOpInline);
    
    private 
    {
        Request _request;
        string input_path;
        string output_path;

        Parser!TemplateLexer _parser;

        string _routeGroup = DEFAULT_ROUTE_GROUP;
        string _locale = "en-us";
    }

    this()
    {
        auto tpl_path = config().view.path;
        if (tpl_path.length == 0)
            tpl_path = "./views/";
        string p = buildPath(APP_PATH, buildNormalizedPath(tpl_path));
        input_path = output_path = p ~ dirSeparator;
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

    Request request() {
        return _request;
    }

    void request(Request value) {
        _request = value;
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
        version (HUNT_FM_DEBUG) trace("parse template file: ", input_path ~ filename);
        return _parser.parseTreeFromFile(input_path ~ filename);
    }

    string render(TemplateNode tree,JSONValue data)
    {
        import hunt.framework.util.uninode.Serialization;

        auto render = new Render(tree);
        render.setRouteGroup(_routeGroup);
        render.setLocale(_locale);
        render.request = _request;
        return render.render(jsonToUniNode(data));
    }

    string renderFile(string path,JSONValue data)
    {
         return render(parse_template(path),data);
    }

    string render(string str,JSONValue data)
    {
        auto tree = _parser.parseTree(str,"",input_path);
        auto render = new Render(tree);
        render.setRouteGroup(_routeGroup);
        render.setLocale(_locale);
        render.request = _request;
        return render.render(jsonToUniNode(data));
    } 
}
