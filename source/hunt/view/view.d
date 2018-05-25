/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Website: www.huntframework.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.view.view;

public import hunt.view.ast;
public import hunt.view.cache;
public import hunt.view.element;
public import hunt.view.environment;
public import hunt.view.match;
public import hunt.view.parser;
public import hunt.view.render;
public import hunt.view.rule;
public import hunt.view.util;

import std.json : JSONValue;

class View
{
    private
    {
        string _templatePath = "./views/";
        string _extName = ".html";
        Environment _env;
    }

    this()
    {
        _env = new Environment(_templatePath);
    }

    public Environment env()
    {
        return _env;
    }

    public View setTemplatePath(string path)
    {
        _templatePath = path;
        _env.setTemplatePath(path);

        return this;
    }

    public View setFileExtension(string fileExt)
    {
        _extName = fileExt;
        return this;
    }

    public string getTemplatePath()
    {
        return _templatePath;
    }

    public string render(string tempalteFile, JSONValue values)
    {
        return _env.render_file(tempalteFile ~ _extName, values);
    }
}

private View _viewInstance;

View GetViewInstance()
{
    if (_viewInstance is null)
    {
        import hunt.application.config;

        _viewInstance = new View;
        _viewInstance.setTemplatePath(Config.app.config.templates.path.value)
                     .setFileExtension(Config.app.config.templates.fileExtension.value);
    }

    return _viewInstance;
}
