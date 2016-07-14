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

public import hunt.routing;
public import hunt.router.middleware;
public import hunt.router.configsignalmodule;
public import hunt.router.configmultiplemodule;
public import hunt.router.config;
import collie.utils.functional;

public import hunt.http.request;
public import hunt.http.response;
public import hunt.application;

alias HTTPRouter = Router!(Request, Response);
alias DOHandler = void delegate(Request, Response);
alias HTTPRouterGroup = RouterGroup!(Request, Response);

void initControllerCall(string FUN, T, ARGS...)(string str, ARGS args) if (
	(is(T == class) || is(T == interface)) && hasMember!(T, FUN))
{
	///dowidget
	auto app = Application.app();
	auto middlewares = app.middlewareFactory.getMiddlewares();
	if(middlewares !is null)
	{
		foreach(w; middlewares)
		{
			///arg0:context
			///arg1 req
			///arg2 res
			if(!w.onProcess(args[1], args[2]))
			{
				args[2].done();
				return;
			}
		}
	}

	import std.experimental.logger;
	
	auto index = lastIndexOf(str, '.');
	if (index < 0 || index == (str.length - 1))
	{
		error("can not find function!, the str is  : ", str);
		return;
	}
	
	string objName = str[0 .. index];
	string funName = str[(index + 1) .. $];
	
	auto obj = Object.factory(objName);
	if (!obj)
	{
		error("Object.factory erro!, the obj Name is : ", objName);
		return;
	}
	auto a = cast(T) obj;
	if (!a)
	{
		error("cast(T)obj; erro!");
		return;
	}
	
	mixin("bool ret = a." ~ FUN ~ "(funName,args);" ~ q{
			if(!ret)
			{
				args[2].done();
				return;
			}
		});
}

void setRouterConfigHelper(string FUN, T, TRouter)(TRouter router, RouterConfigBase config) if (
        (is(T == class) || is(T == interface)) && hasMember!(T, FUN) && hasMember!(TRouter, "addRouter"))
{
    import std.string;
    import std.array;

	alias doFun = initControllerCall!(FUN, T,RouterPipelineContext, Request, Response);
	alias MiddleWareFactory = AutoMiddleWarePipelineFactory!(Request, Response);
    
    
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
        auto list = split(item.method, ',');
        switch(item.routerType)
        {
            case RouterType.DEFAULT:
            case RouterType.DIR:
            {
                foreach (ref str; list)
                {
                    if (str.length == 0)
                        continue;
                    string path = getDirPath(item.routerType,item.dir,item.path);
                    router.addRouter(str, path, bind(&doFun, item.hander),
                        new shared MiddleWareFactory(item.middleWareBefore),
                        new shared MiddleWareFactory(item.middleWareAfter));
                }
            }
                break;
                
static if(hasMember!(TRouter,"getRouter"))
{
            case RouterType.DOMAIN_DIR:
            case RouterType.DOMAIN:
            {
                foreach (ref str; list)
                {
                    if (str.length == 0)
                        continue;
                    string path = getDirPath(item.routerType,item.dir,item.path);
                    router.addRouter(item.host,str, path, bind(&doFun, item.hander),
                        new shared MiddleWareFactory(item.middleWareBefore),
                        new shared MiddleWareFactory(item.middleWareAfter));
                }
            }
            break;
}
            default:
                break;
        }
    }
}

 
