/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.router.routegroup;

import hunt.router.define;
import hunt.router.route;

class RouteGroup
{
    this(string name = DEFAULT_ROUTE_GROUP)
    {
        this._name = name;
    }

    public
    {
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
                this._routes[route.getPattern()] = route;
            }

            string mca = ((route.getModule()) ? route.getModule() ~ "." : "") ~ route.getController() ~ "." ~ route.getAction();

            this._mcaRoutes[mca] = route;

            return this;
        }

        Route getRoute(string mca)
        {
            return this._mcaRoutes.get(mca, null);
        }

        Route match(string path)
        {
            // TODO: 引用类型使用结构体二次包装
            Route route;

            tracef("Match in group: %s, %s", this._name, this._routes);

            route = this._routes.get(path, null);

            if (route)
            {
                return route;
            }
            else
            {
            	foreach(key, value; this._routes)
            	{
            		import std.string;
            		if (path.startsWith(key))
            		{
            			route = this._routes.get(key, null);
            			
            			if (route.staticFilePath != string.init)
            			{
            				return route;
            			}
            		}
            	}
            }

            import std.regex;
            
            foreach (r; this._regexRoutes)
            {
                auto matched = path.match(regex(r.getPattern()));

                if (matched)
                {
                    route = r;

                    string[string] params;

                    foreach(i, key; route.getParamKeys())
                    {
                        params[key] = matched.captures[i + 1];
                    }

                    route.setParams(params);

                    return route;
                }
            }

            return null;
        }
    }

    private
    {
        string _name;
        Route[string] _routes;
        Route[string] _mcaRoutes;
        Route[] _regexRoutes;
    }
}
