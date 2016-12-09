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

void initControllerCall(string FUN, T)(string str, Request args) if (
	(is(T == class) || is(T == interface)) && hasMember!(T, FUN))
{
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
		throw new RourerFactoryException("Object.factory erro!, the obj Name is : "~objName);
	auto a = cast(T) obj;
	if (!a)
		throw new RourerFactoryException("cast("~ FUN ~")obj; erro!"~objName );
	mixin("bool ret = a." ~ FUN ~ "(funName,args);" ~ q{
			if(!ret)
			{
				Response res = args.createResponse();
				res.done();
				return;
			}
		});
}

void setRouterConfigHelper(string FUN, T)(RouterConfigBase config) if (
        (is(T == class) || is(T == interface)) && hasMember!(T, FUN) )
{
    import std.string;
    import std.array;

	alias doFun = initControllerCall!(FUN, T);
    
    
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
					defaultRouter.addRoute(str, path, bind(&doFun, item.hander));
                }
            }
                break;
            case RouterType.DOMAIN_DIR:
            case RouterType.DOMAIN:
            {
                foreach (ref str; list)
                {
                    if (str.length == 0)
                        continue;
                    string path = getDirPath(item.routerType,item.dir,item.path);
					defaultRouter.addRoute(item.host,str, path, bind(&doFun, item.hander));
                }
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