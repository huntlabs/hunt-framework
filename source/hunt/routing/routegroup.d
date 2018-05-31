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

module hunt.routing.routegroup;

import hunt.routing.define;
import hunt.routing.route;

import std.algorithm.searching;
import std.string;

class RouteInfo
{
    string mca;
    string path;
    HTTP_METHODS[] methods;

    this(string mca, string path, HTTP_METHODS[] methods)
    {
        this.mca = mca;
        this.path = path;
        this.methods = methods;
    }
}

class RoutePathInfo
{
    string path;
    HTTP_METHODS[] methods;

    this(string path, HTTP_METHODS[] methods)
    {
        this.path = path;
        this.methods = methods;
    }
}

class RouteRegInfo
{
    HTTP_METHODS[] methods;
    this(HTTP_METHODS[] methods)
    {
        this.methods = methods;
    }
}

class RouteGroup
{
    this(string name = DEFAULT_ROUTE_GROUP)
    {
        this._name = name;
    }

    void setName(string name)
    {
        this._name = name;
    }

    string getName()
    {
        return this._name;
    }

    RouteGroup addRoute(Route route)
    {
        if (route.getRegular())
        {
            this._regexRoutes ~= route;
        }
        else
        {
            //path 
            this._routes[new RoutePathInfo(route.getPattern(), route.getMethods)] = route;
        }

        string mca = ((route.getModule()) ? route.getModule() ~ "." : "") ~ route.getController()
            ~ "." ~ route.getAction();

        this._mcaRoutes[new RouteInfo(mca, route.getPattern, route.getMethods)] = route;

        return this;
    }

    Route getRoute(string method, string mca)
    {
        auto m = getMethod(method);
        foreach (k, v; _mcaRoutes)
        {
            if (k.mca == mca)
            {
                if (canFind(k.methods, m) || k.methods == [HTTP_METHODS.ALL])
                    return v;
            }
        }
        return null;
    }

    bool exists(string method, string path)
    {
        Route r = match(method, path);
        return r !is null;
    }

    Route match(string method, string path)
    {
        Route route = null;

        auto http_method = getMethod(toUpper(method));
        foreach (k, v; _routes)
        {
            if (k.path == path)
            {
                if (canFind(k.methods, http_method) || k.methods == [HTTP_METHODS.ALL])
                    route = v;
            }
        }

        if (route)
        {
            return route.copy();
        }
        else
        {
            foreach (key, value; this._routes)
            {
                import std.string;
                import std.algorithm.searching;

                if (startsWith(path, key.path) && value.staticFilePath.length > 0
                        && (canFind(key.methods, http_method) || key.methods == [HTTP_METHODS.ALL]))
                {
                    return value;
                }
            }
        }

        import std.regex;
        import std.uri : decode;

        foreach (r; this._regexRoutes)
        {
            auto matched = path.match(regex(r.getPattern()));
            bool matchMethod = false;
            if (canFind(r.getMethods, http_method) || r.getMethods == [HTTP_METHODS.ALL])
                matchMethod = true;
            if (matched && matchMethod)
            {
                route = r.copy();
                string[string] params;
                foreach (i, key; route.getParamKeys())
                {
                    params[key] = decode(matched.captures[i + 1]);
                }

                route.setParams(params);
                return route;
            }
        }

        return null;
    }

    private
    {
        string _name;
        Route[RoutePathInfo] _routes;
        Route[RouteInfo] _mcaRoutes;
        Route[] _regexRoutes;
    }
}
