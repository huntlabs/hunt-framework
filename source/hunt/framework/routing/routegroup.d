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

module hunt.framework.routing.routegroup;

import hunt.framework.routing.define;
import hunt.framework.routing.route;

import std.algorithm;
import std.string;
import std.regex;
import std.uri : decode;
import kiss.logger;

/**
*/
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

/**
*/
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

/**
*/
class RouteRegInfo
{
    HTTP_METHODS[] methods;
    this(HTTP_METHODS[] methods)
    {
        this.methods = methods;
    }
}

/**
*/
class RouteGroup
{
    this(string name = DEFAULT_ROUTE_GROUP)
    {
        this._name = name;
    }

    RouteGroup setName(string name)
    {
        this._name = name;
	return this;
    }

    string getName()
    {
        return this._name;
    }

    RouteGroup setType(string type)
    {
        this._type = type;
	return this;
    }

    string getType()
    {
        return this._type;
    }

    RouteGroup setValue(string value)
    {
        this._value = value;
	return this;
    }

    string getValue()
    {
        return this._value;
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

        HTTP_METHODS http_method = getMethod(toUpper(method));
        foreach (RoutePathInfo k, Route v; _routes)
        {
            // tracef("key path: %s, getMethods: %s, request: %s", k.path, v.getMethods(), path);
            if (k.path == path && (canFind(k.methods, http_method) || k.methods
                    == [HTTP_METHODS.ALL]))
            {
                return v;
            }
        }

        // 
        foreach (r; this._regexRoutes)
        {
            auto matched = path.match(regex(r.getPattern()));

            if (matched && (canFind(r.getMethods, http_method) || r.getMethods == [HTTP_METHODS.ALL]))
            {
                if(matched.captures[0] != path)
                    continue;
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

        //
        foreach (key, value; _routes)
        {
            // tracef("key path: %s, getMethods: %s, request: %s", key.path, value.getMethods(), path);
            if (startsWith(path, key.path) && value.staticFilePath.length > 0
                    && (canFind(key.methods, http_method) || key.methods == [HTTP_METHODS.ALL]))
            {
                return value;
            }
        }


        return null;
    }

    private
    {
        string _name;
	string _type;
	string _value;

        Route[RoutePathInfo] _routes;
        Route[RouteInfo] _mcaRoutes;
        Route[] _regexRoutes;
    }
}
