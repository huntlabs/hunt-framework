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

module hunt.routing.router;

import hunt.routing.define;
import hunt.routing.routegroup;
import hunt.routing.route;
import hunt.routing.config;

import hunt.application.controller;

import std.algorithm.mutation;
import std.string;
import std.file;
import std.path;
import std.array;

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
            this._configPath = (path[$ - 1] == '/') ? path : path ~ "/";
        }

        string createUrl(string mca, string[string] params, string group = DEFAULT_ROUTE_GROUP)
        {
            // find Route
            RouteGroup routeGroup = this.getGroup(group);
            if (routeGroup is null)
            {
                return "#";
            }

            Route route = routeGroup.getRoute("", mca);
            if (route is null)
            {
                return "#";
            }

            string url;
            if (route.getRegular() == true)
            {
                if (params.length == 0)
                {
                    logWarningf("this route need params (%s).", mca);
                    return "#";
                }

                if (route.getParamKeys().length > 0)
                {
                    url = route.getUrlTemplate();
                    import std.array : replaceFirst;

                    foreach (i, key; route.getParamKeys())
                    {
                        string value = params.get(key, null);

                        if (value is null)
                        {
                            logWarningf("this route template need param (%s).", key);

                            return "#";
                        }

                        params.remove(key);
                        url.replaceFirst("{" ~ key ~ "}", value);
                    }
                }
            }
            else
            {
                url = route.getPattern();
            }

            return url ~ (params.length > 0 ? ("?" ~ buildUriQueryString(params)) : "");
        }

        string buildUriQueryString(string[string] params)
        {
            if (params.length == 0)
            {
                return "";
            }

            string uriQueryString;

            foreach (k, v; params)
            {
                uriQueryString ~= (uriQueryString ? "&" : "") ~ k ~ "=" ~ v;
            }

            return uriQueryString;
        }

        void addGroup(string group, string method, string value)
        {
            RouteGroup routeGroup = ("domain" == method) ? _domainGroups.get(group,
                    null) : _directoryGroups.get(group, null);

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

        RouteGroup getGroup(string group = DEFAULT_ROUTE_GROUP)
        {
            if (false == this._supportMultipleGroup)
            {
                return this._defaultGroup;
            }

            RouteGroup routeGroup = this._groups.get(group, null);

            if (routeGroup is null)
            {
                return null;
            }

            return routeGroup;
        }

        void loadConfig()
        {
            this.loadConfig(DEFAULT_ROUTE_GROUP);

            if (!this._supportMultipleGroup)
            {
                logDebug("Router multiple route group is disabled!");
                return;
            }
            else
            {
                logDebug("Router multiple route group is enabled..");
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

        Router addRoute(string method, string path, HandleFunction handle,
                string group = DEFAULT_ROUTE_GROUP)
        {
            RouteGroup routeGroup = _defaultGroup;
            if (group != DEFAULT_ROUTE_GROUP)
                routeGroup = this._groups.get(group, null);
            if (routeGroup !is null)
            {
                Route r = routeGroup.match(method, path);
                if (r is null)
                    this.addRoute(this.makeRoute!HandleFunction(method, path, handle, group));
                else
                    throw new Exception("Repeated route: " ~ path);
            }

            return this;
        }

        private Router addRoute(Route route, string group = DEFAULT_ROUTE_GROUP)
        {
            if (group == DEFAULT_ROUTE_GROUP)
            {
                this._defaultGroup.addRoute(route);
                return this;
            }

            RouteGroup routeGroup = this._groups.get(group, null);
            if (!routeGroup)
            {
                routeGroup = new RouteGroup(group);
                this._groups[group] = routeGroup;
            }

            routeGroup.addRoute(route);

            return this;
        }

        private Route staticRootRoute;

        Route match(string domain, string method, string path)
        {
            Route r;
            version (HuntDebugMode)
                tracef("matching: domain=%s, method=%s, path=%s", domain, method, path);
            path = this.mendPath(path);

            if (false == this._supportMultipleGroup)
            {
                // don't support multiple route group, use defualt group match function
                r = this._defaultGroup.match(method, path);
                if (path == "/" && r is null)
                    return staticRootRoute;
                else
                    return r;
            }

            RouteGroup routeGroup = this.getGroupByDomain(domain);
            if (!routeGroup)
            {
                if (path.length > 1)
                {
                    import std.array;

                    // TODO: Here is a bug
                    string directory = split(path, "/")[1];

                    routeGroup = this.getGroupByDirectory(directory);
                    if (routeGroup)
                    {
                        path = path[directory.length + 1 .. $];
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

            version (HuntDebugMode)
                tracef("matching2: domain=%s, method=%s, path=%s", domain, method, path);
            r = routeGroup.match(method, path);
            if (path == "/" && r is null)
                return staticRootRoute;
            else
                return r;
        }

        string mendPath(string path)
        {
            if (path != "/")
            {
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
            logDebugf("loading config for %s", group);

            if (group == DEFAULT_ROUTE_GROUP)
            {
                routeGroup = this._defaultGroup;
            }
            else
            {
                routeGroup = this._groups.get(group, null);
                if (routeGroup is null)
                {
                    logWarningf("Group [%s] non-existent.", group);
                    return;
                }
            }

            string configFile = (DEFAULT_ROUTE_GROUP == group) ? this._configPath ~ "routes"
                : this._configPath ~ group ~ ".routes";
            if (!exists(configFile))
                return;

            // read file content
            RouteConfig config;
            RouteItem[] items = config.loadConfig(configFile);

            bool haveRootRoute = false;
            Route route;
            foreach (item; items)
            {
                if(routeGroup.exists(item.methods, this.mendPath(item.path)))
                {
                    throw new Exception("Repeated route: " ~ item.path);
                }

                if (item.path == "/")
                    haveRootRoute = true;
                route = this.makeRoute(item.methods, item.path, item.route, group);
                if (route)
                {
                    routeGroup.addRoute(route);
                }
            }

            this.staticRootRoute = this.makeRoute("GET", "/", "staticDir:wwwroot/", group);
            if (!haveRootRoute)
                routeGroup.addRoute(staticRootRoute);
        }



        RouteGroup getGroupByDomain(string domain)
        {
            return this._domainGroups.get(domain, null);
        }

        RouteGroup getGroupByDirectory(string directory)
        {
            return this._directoryGroups.get(directory, null);
        }

        Route makeRoute(T = string)(string methods, string path, T mca,
                string group = DEFAULT_ROUTE_GROUP)
        {
            version (HuntDebugMode)
                tracef("method: %s, path: %s, mca: %s, group: %s", methods, path, mca, group);
            auto route = new Route();
            methods = toUpper(methods);
            path = this.mendPath(path);
            route.path = path;

            route.setGroup(group);
            route.setPattern(path);
            auto arr = split(methods, ",");
            HTTP_METHODS[] http_methods;
            foreach (v; arr)
            {
                http_methods ~= getMethod(v);
            }
            route.setMethods(http_methods);

            static if (is(T == string))
            {
                route.setRoute(mca);

                import std.algorithm;
                import std.string;

                if (mca.startsWith("staticDir:"))
                {
                    route.setModule("hunt.application.staticfile");
                    route.setController("staticfile");
                    route.setAction("doStaticFile");
                    route.staticFilePath = mca.chompPrefix("staticDir:");
                }
                else
                {
                    string[] mcaArray = split(mca, ".");

                    if (mcaArray.length > 3 || mcaArray.length < 2)
                    {
                        logWarningf("this route config mca length is: %d (%s)",
                                mcaArray.length, mca);
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

                    auto matches = path.matchAll(regex(`:(\w+)`));
                    if (matches)
                    {
                        string[int] paramKeys;
                        int paramCount = 0;
                        string pattern = path;
                        string urlTemplate = path;

                        foreach (m; matches)
                        {
                            paramKeys[paramCount] = m[1];
                            pattern = pattern.replaceFirst(m[0], "([^/]*)");
                            urlTemplate = urlTemplate.replaceFirst(m[0], "{" ~ m[1] ~ "}");
                            paramCount++;
                        }

                        route.setPattern(pattern);
                        route.setParamKeys(paramKeys);
                        route.setRegular(true);
                        route.setUrlTemplate(urlTemplate);
                    }
                }

                string handleKey = this.makeRequestHandleKey(route);

                route.handle = getRouteFromList(handleKey);
            }
            else
            {
                route.handle = mca;
            }

            if (route.handle is null)
            {
                logDebugf("handle is null (%s).", route.getPattern());
                return null;
            }

            return route;
        }

        string makeRequestHandleKey(Route route)
        {
            string handleKey;

            if (route.staticFilePath == string.init)
            {
                if (route.getModule() == null)
                {
                    handleKey = "app.controller." ~ ((route.getGroup() == DEFAULT_ROUTE_GROUP) ? ""
                            : route.getGroup() ~ ".") ~ route.getController() ~ "." ~ route.getController()
                        ~ "controller." ~ route.getAction();
                }
                else
                {
                    handleKey = "app." ~ route.getModule() ~ ".controller." ~ ((route.getGroup() == DEFAULT_ROUTE_GROUP)
                            ? "" : route.getGroup() ~ ".") ~ route.getController() ~ "." ~ route.getController()
                        ~ "controller." ~ route.getAction();
                }
            }
            else
            {
                handleKey = "hunt.application.staticfile.StaticfileController.doStaticFile";
            }

            import std.string : toLower;

            return handleKey.toLower();
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

        import hunt.init;

        alias _configPath = DEFAULT_CONFIG_PATH;
    }
}
