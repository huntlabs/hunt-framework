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
module hunt.web.router;

public import hunt.web.router.router;
public import hunt.web.router.routergroup;
public import hunt.web.router.configbase;
public import hunt.web.router.configsignalmodule;
public import hunt.web.router.configmultiplemodule;
public import hunt.web.router.utils;
public import hunt.web.router.middleware;

import collie.utils.functional;

void setRouterConfigHelper(string FUN, T, TRouter)(TRouter router, RouterConfigBase config) if (
        (is(T == class) || is(T == interface)) && hasMember!(T, FUN) && hasMember!(TRouter, "addRouter"))
{
    import std.string;
    import std.array;

    alias doFun = controllerHelper!(FUN, T, TRouter.Request, TRouter.Response);
    alias MiddleWareFactory = AutoMiddleWarePipelineFactory!(TRouter.Request, TRouter.Response);
    
    
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

