module hunt.router;

public import hunt.router.router;
public import hunt.router.routerconfig;
public import hunt.router.utils;
public import hunt.router.middleware;

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
