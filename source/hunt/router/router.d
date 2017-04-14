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

module hunt.router.router;

import hunt.router.define;
import hunt.router.routegroup;
import hunt.router.route;
import hunt.router.config;

import hunt.application.controller;

class Router
{
    public
    {
        this()
        {
            this._defaultGroup = new RouteGroup(DEFAULT_ROUTE_GROUP);
        }

        void setConfigPath(string path)
        {
            // supplemental slash
            this._configPath = (path[path.length-1] == '/') ? path : path ~ "/";
        }

        void addGroup(string group, string method, string value)
        {
            RouteGroup routeGroup = ("domain" == method) ? _domainGroups.get(group, null) : _directoryGroups.get(group, null);

            if (routeGroup is null)
            {
                routeGroup = new RouteGroup(group);

                _groups[group] = routeGroup;

                if ("domain" == method)
                {
                    _domainGroups[value] = routeGroup;
                }
                else
                {
                    _directoryGroups[value] = routeGroup;
                }

                this._supportMultipleGroup = true;
            }
        }

        void loadConfig()
        {
            this.loadConfig(DEFAULT_ROUTE_GROUP);

            if (!this._supportMultipleGroup)
            {
                trace("Router multiple route group is disabled!");

                return;
            }
            else
            {
                trace("Router multiple route group is enabled..");
            }

            // load this group routes from config file
            foreach (key, obj; this._groups)
            {
                this.loadConfig(key);
            }
        }

        void setSupportMultipleGroup(bool enabled = true)
        {
            this._supportMultipleGroup = enabled;
        }

        Router addRoute(string method, string path, HandleFunction handle, string group = DEFAULT_ROUTE_GROUP)
        {
            this.addRoute(this.makeRoute!HandleFunction(method, path, handle, group));

            return this;
        }

        Router addRoute(Route route, string group = DEFAULT_ROUTE_GROUP)
        {
            if (group == DEFAULT_ROUTE_GROUP)
            {
                this._defaultGroup.addRoute(route);

                return this;
            }

            RouteGroup routeGroup = this._groups.get(group,null);
            if (!routeGroup)
            {
                routeGroup = new RouteGroup(group);

                this._groups[group] = routeGroup;
            }

            routeGroup.addRoute(route);

            return this;
        }

        Route match(string domain, string method, string path)
        {
            path = this.mendPath(path);

            if (false == this._supportMultipleGroup)
            {
                // don't support multiple route group, use defualt group match function
                return this._defaultGroup.match(path);
            }

            RouteGroup routeGroup;

            routeGroup = this.getGroupByDomain(domain);

            if (!routeGroup)
            {
                if (path.length > 1)
                {
                    import std.array;
                    // TODO: this is bug
                    string directory = split(path, "/")[1];

                    tracef("Directory is %s.", directory);
                    routeGroup = this.getGroupByDirectory(directory);
                    if (routeGroup)
                    {
                        path = path[directory.length+1 .. $];
                    }
                    else
                    {
                        routeGroup = this._defaultGroup;
                    }
                }
                else
                {
                    routeGroup = this._defaultGroup;
                }
            }

            tracef("Route group is: %s, path: %s", routeGroup.getName(), path);

            return routeGroup.match(path);
        }

        string mendPath(string path)
        {
            if (path != "/")
            {
                import std.algorithm.mutation : strip;

                return "/" ~ path.strip('/') ~ "/";
            }

            return path;
        }
    }

    private
    {
        //
        void loadConfig(string group = DEFAULT_ROUTE_GROUP)
        {
            RouteGroup routeGroup;

            tracef("load config for %s", group);

            if (group == DEFAULT_ROUTE_GROUP)
            {
                routeGroup = this._defaultGroup;
            }
            else
            {
                routeGroup = this._groups.get(group, null);
                if (routeGroup is null)
                {
                    warningf("Group [%s] non-existent.", group);
                    return;
                }
            }

            string configFile = (DEFAULT_ROUTE_GROUP == group) ? this._configPath ~ "routes" : this._configPath ~ group ~ ".routes";
            
            // read file content
            RouteConfig config;
            RouteItem[] items = config.loadConfig(configFile);

            Route route;

            foreach (item; items)
            {
                route = this.makeRoute(item.methods, item.path, item.route, group);
                if (route)
                {
                    routeGroup.addRoute(route);
                }
            }
        }

        RouteGroup getGroupByDomain(string domain)
        {
            return this._domainGroups.get(domain, null);
        }

        RouteGroup getGroupByDirectory(string directory)
        {
            return this._directoryGroups.get(directory, null);
        }

        Route makeRoute(T = string)(string methods, string path, T mca, string group = DEFAULT_ROUTE_GROUP)
        {
            auto route = new Route();

            import std.string : toUpper;

            methods = toUpper(methods);

            path = this.mendPath(path);

            route.setGroup(group);
            route.setPattern(path);

            static if (is (T == string))
            {
                route.setRoute(mca);

                import std.string : split;
                string[] mcaArray = split(mca, ".");

                if (mcaArray.length > 3 || mcaArray.length < 2)
                {
                    warningf("this route config mca length is: %d (%s)", mcaArray.length, mca);
                    return null;
                }

                if (mcaArray.length == 2)
                {
                    route.setController(mcaArray[0]);
                    route.setAction(mcaArray[1]);
                }
                else
                {
                    route.setModule(mcaArray[0]);
                    route.setController(mcaArray[1]);
                    route.setAction(mcaArray[2]);
                }

                import std.regex;
                import std.array;

                auto matches = path.matchAll(regex(`<(\w+):([^>]+)>`));
                if (matches)
                {
                    string[int] paramKeys;
                    int paramCount = 0;
                    string pattern = path;
                    string urlTemplate = path;

                    foreach (m; matches)
                    {
                        paramKeys[paramCount] = m[1];
                        pattern = pattern.replaceFirst(m[0], "(" ~ m[2] ~ ")");
                        urlTemplate = urlTemplate.replaceFirst(m[0], "{" ~ m[1] ~ "}");
                        paramCount++;
                    }

                    route.setPattern(pattern);
                    route.setParamKeys(paramKeys);
                    route.setRegular(true);
                    route.setUrlTemplate(urlTemplate);
                }

                string handleKey = this.makeRequestHandleKey(route);

                trace(handleKey);

                route.handle = getRouteFormList(handleKey);
            }
            else
            {
                route.handle = mca;
            }

            if (route.handle is null)
            {
                tracef("handle is null (%s).", route.getPattern());
                return null;
            }

            return route;
        }

        string makeRequestHandleKey(Route route)
        {
            string handleKey;
            
            if (route.getModule() == null)
            {
                handleKey = "app.controller." ~ ((route.getGroup() == DEFAULT_ROUTE_GROUP) ? "" : route.getGroup() ~ ".") ~ route.getController() ~ "." ~ route.getController() ~ "controller." ~ route.getAction();
            }
            else
            {
                handleKey = "app." ~ route.getModule() ~ ".controller." ~ ((route.getGroup() == DEFAULT_ROUTE_GROUP) ? "" : route.getGroup() ~ ".") ~ route.getController() ~ "." ~ route.getController() ~ "controller." ~ route.getAction();
            }
            
            return handleKey;
        }
    }

    private
    {
        RouteGroup _defaultGroup;

        RouteGroup[string] _directoryGroups;
        RouteGroup[string] _domainGroups;
        RouteGroup[string] _groups;

        // enable muiltple route group
        bool _supportMultipleGroup = false;

        string _configPath = "config/";
    }
}
