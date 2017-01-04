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
 
module hunt.router;

import std.string;
import std.regex;
import std.traits;

import hunt.router.config;
public import hunt.router.router;
public import hunt.router.routergroup;
public import hunt.router.build;
import collie.utils.functional;

import hunt.router.configbase;
public import hunt.http.request;
public import hunt.http.response;

void setRouterConfigHelper(RouterConfigBase config)
{
	import hunt.application.controller;
    
    string getDirPath(RouterType type, string dir, string path)
    {
        if(type == RouterType.DEFAULT || type == RouterType.DOMAIN) return path;
        if(path.length == 0) return dir;
        if(dir.length == 0) return path;
        string tpath = dir;
        char dl = tpath[tpath.length -1];
        char pf = path[0];
        if(dl == '/' &&  pf == '/')
        {
            tpath ~= path[0..$];
        } 
        else if(dl == '/' ||  pf == '/')
        {
            tpath ~= path;
        }
        else
        {
            tpath ~= "/";
            tpath ~= path;
        }
        if(tpath[0] != '/')
            tpath = "/" ~ tpath;
        return tpath;
    }

    RouterContext[] routeList = config.doParse();
    foreach (ref item; routeList)
    {
		RouterHandler.HandleFunction fun = getRouteFormList(item.hander);
		if(fun is null) continue;

        //auto list = split(item.method, ',');
        switch(item.routerType)
        {
            case RouterType.DEFAULT:
            case RouterType.DIR:
            {
				string path = getDirPath(item.routerType,item.dir,item.path);
				addRouteHelp("",item.method,path,fun);
            }
                break;
            case RouterType.DOMAIN_DIR:
            case RouterType.DOMAIN:
            {
				string path = getDirPath(item.routerType,item.dir,item.path);
				addRouteHelp(item.host,item.method,path,fun);
            }
            break;
            default:
                break;
        }
    }
}


import collie.utils.exception;
import hunt.exception;

mixin ExceptionBuild!("RourerFactory","Hunt");