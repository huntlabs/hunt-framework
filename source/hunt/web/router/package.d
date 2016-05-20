module hunt.web.router;

public import hunt.web.router.router;
public import hunt.web.router.routerconfig;
public import hunt.web.router.utils;
public import hunt.web.router.middleware;

import collie.utils.functional;

void setRouterConfigHelper(string FUN, T, REQ, RES)(Router!(REQ, RES) router, RouterConfig config) if (
        (is(T == class) || is(T == interface)) && hasMember!(T, FUN))
{
    import std.string;
    import std.array;

    alias doFun = controllerHelper!(FUN, T, REQ, RES);
    alias MiddleWareFactory = AutoMiddleWarePipelineFactory!(REQ, RES);

    RouterContext[] routeList = config.doParse();
    foreach (ref item; routeList)
    {
        auto list = split(item.method, ',');
        foreach (ref str; list)
        {
            if (str.length == 0)
                continue;
            router.addRouter(str, item.path, bind(&doFun, item.hander),
                new shared MiddleWareFactory(item.middleWareBefore),
                new shared MiddleWareFactory(item.middleWareAfter));
        }
    }
}

void setGroupRouterConfigHelper(string FUN, T, REQ, RES)(Router!(REQ, RES) router, RouterConfig config) if (
        (is(T == class) || is(T == interface)) && hasMember!(T, FUN))
{
    import std.string;
    import std.array;

    alias doFun = controllerHelper!(FUN, T, REQ, RES);
    alias MiddleWareFactory = AutoMiddleWarePipelineFactory!(REQ, RES);

    RouterContext[] routeList = config.doParse();
    foreach (ref item; routeList)
    {
        auto list = split(item.method, ',');
	std.stdio.writeln("item.hander: ", item.hander);
        foreach (ref str; list)
        {
            if (str.length == 0)
                continue;
	    if(item.routerType == RouterType.DOMAIN)
		router.addGroupRouter(item.host, str, item.path, bind(&doFun, item.hander),
		    new shared MiddleWareFactory(item.middleWareBefore),
		    new shared MiddleWareFactory(item.middleWareAfter));
	    else if(item.routerType == RouterType.DIR)
		router.addGroupRouter(item.dir, str, item.path, bind(&doFun, item.hander),
		    new shared MiddleWareFactory(item.middleWareBefore),
		    new shared MiddleWareFactory(item.middleWareAfter));
	    else
		router.addGroupRouter(item.host, str, item.path, bind(&doFun, item.hander),
		    new shared MiddleWareFactory(item.middleWareBefore),
		    new shared MiddleWareFactory(item.middleWareAfter));
        }
    }
}
