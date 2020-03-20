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

module hunt.framework.view.View;

import hunt.framework.view.Environment;
import hunt.framework.view.Template;
import hunt.framework.view.Util;
import hunt.framework.view.Exception;
import hunt.framework.Init;

// import hunt.framework.Simplify;

import hunt.util.Serialize;
import hunt.logging;

import std.json : JSONValue;
import std.path;

class View {
    private {
        string _templatePath = "./views/";
        string _extName = ".html";
        uint _arrayDepth = 3;
        Environment _env;
        string _routeGroup = DEFAULT_ROUTE_GROUP;
        JSONValue _context;
    }

    this(Environment env) {
        _env = env;
    }

    Environment env() {
        return _env;
    }

    View setTemplatePath(string path) {
        _templatePath = path;
        _env.setTemplatePath(path);

        return this;
    }

    View setTemplateExt(string fileExt) {
        _extName = fileExt;
        return this;
    }

    string getTemplatePath() {
        return _templatePath;
    }

    View setRouteGroup(string rg) {
        _routeGroup = rg;
        //if (_routeGroup != DEFAULT_ROUTE_GROUP)
        _env.setRouteGroup(rg);
        _env.setTemplatePath(buildNormalizedPath(_templatePath) ~ dirSeparator ~ _routeGroup);

        return this;
    }

    View setLocale(string locale) {
        _env.setLocale(locale);
        return this;
    }

    int arrayDepth() {
        return _arrayDepth;
    }

    View arrayDepth(int value) {
        _arrayDepth = value;
        return this;
    }

    string render(string tempalteFile) {
        version (HUNT_VIEW_DEBUG) {
            tracef("---tempalteFile: %s, _extName:%s, rend context: %s",
                    tempalteFile, _extName, _context.toString);
        }
        return _env.renderFile(tempalteFile ~ _extName, _context);
    }

    void assign(T)(string key, T t) {
        this.assign(key, toJson(t, _arrayDepth));
    }

    void assign(string key, JSONValue t) {
        _context[key] = t;
    }
}

// __gshared private Environment _envInstance;

// View GetViewObject()
// {
//     import hunt.framework.config.ApplicationConfig;
//     auto view = new View(new Environment);

//     string path = buildNormalizedPath(APP_PATH, config().view.path);

//     version (HUNT_DEBUG) {
//         tracef("setting view path: %s", path);
//     }
//     view.setTemplatePath(path).setTemplateExt(config().view.ext);
//     return view;
// }
