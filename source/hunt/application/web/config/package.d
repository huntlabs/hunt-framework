/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */
module hunt.application.web.config;

import std.string;

import hunt.routing.configbase;
public import hunt.application.web.config.http;

class WebConfig
{
    this(string path)
    {
        import hunt.web.router.config;
        if(!endsWith(path,"/"))
            path ~= "/";
        _http = new HTTPConfig(path ~ "http.conf");
        _router = new RouterConfig(path ~ "routes.conf");
    }
    
    this()
    {
        this("config");
    }
    
    
    @property httpConfig(){return _http;}
    @property routerConfig(){return _router;}
private:
    HTTPConfig _http;
    RouterConfigBase _router;
}

