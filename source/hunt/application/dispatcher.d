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

module hunt.application.dispatcher;

import hunt.routing;
import hunt.http.request;
import hunt.http.response;
import hunt.http.exception;

import hunt.simplify;
import hunt.application.controller;
import hunt.application.config;

import hunt.security.acl.Identity;
import hunt.security.acl.Manager;
import hunt.security.acl.User;

import collie.utils.exception;
import collie.codec.http;

import std.stdio;
import std.exception;
import std.parallelism;
import std.conv : to;

import kiss.logger;

class Dispatcher
{
    this()
    {
        this._router = new Router;
        this._router.setConfigPath(Config.path);
    }

    public
    {
        void dispatch(Request request) nothrow
        {
            try
            {
                Route route;

                string cacheKey = request.header(
                        HTTPHeaderCode.HOST) ~ "_" ~ request.method ~ "_" ~ request.path;
                route = this._cached.get(cacheKey, null);

                if (route is null)
                {
                    import std.array : split;
                    string domain = split(request.header(HTTPHeaderCode.HOST), ":")[0];
                    route = this._router.match(domain, request.method, request.path);

                    if (route is null)
                    {
                        request.createResponse().do404();

                        return;
                    }

                    this._cached[cacheKey] = route;
                }

                // add route's params
                auto params = route.getParams();
                if (params.length > 0)
                {
                    foreach (param, value; params)
                    {
                        request.Header().setQueryParam(param, value);
                    }
                }

                request.route = route;

                // hunt.security filter
                request.user = authenticateUser(request);

                if (!accessFilter(request))
                {
                    request.createResponse()
                        .do403("no permiss to access: " ~ request.route.getController() ~ "." ~ request.route.getAction());
                    return;
                }

                // add handle task to taskPool
                this._taskPool.put(task!doRequestHandle(route.handle, request));
            }
            catch (Exception e)
            {
                showException(e);
            }
        }

        bool accessFilter(Request request)
        {
            //兼容老的.
            Identity identity = app().accessManager().getIdentity(request.route.getGroup());

            if (identity is null || request.route.getController().length == 0)
                return true;

            string persident;
            if (request.route.getModule() is null)
            {
                persident = request.route.getController() ~ "." ~ request.route.getAction();
                if (persident == "staticfile.doStaticFile" || identity.isAllowAction(persident))
                    return true;
            }
            else
            {
                persident = request.route.getModule() ~ "." ~ request.route.getController()
                    ~ "." ~ request.route.getAction();
                if (persident == "hunt.application.staticfile.staticfile.doStaticFile"
                        || identity.isAllowAction(persident))
                    return true;
            }

            return request.user.can(persident);
        }

        User authenticateUser(Request request)
        {
            User user;
            Identity identity = app().accessManager()
                .getIdentity(request.route.getGroup());
            if (identity !is null)
            {
                user = identity.login(request);
            }

            if (user is null)
            {
                return User.defaultUser;
            }

            return user;
        }

        void addRouteGroup(string group, string method, string value)
        {
            this._router.addGroup(group, method, value);
        }

        void setWorkers(TaskPool taskPool)
        {
            this._taskPool = taskPool;
        }

        void loadRouteGroups()
        {
            router.loadConfig();
        }

        @property router()
        {
            return this._router;
        }
    }

    private
    {
        Router _router;
        Route[string] _cached;
        __gshared TaskPool _taskPool;
    }
}

void doRequestHandle(HandleFunction handle, Request req)
{
    Response response;
    
    // this thread _request
    request(req);

    try
    {
        response = handle(req);
        if (response is null)
            response = req.createResponse;
    }
    catch (CreateResponseException e)
    {
        showException(e);
    }
    catch (Exception e)
    {
        showException(e);
        response = req.createResponse;
        response.setStatus(502);
        response.setContent(e.toString());
        response.connectionClose();
    }
    catch (Error e)
    {
        import std.stdio : writeln;
        import core.stdc.stdlib : exit;

        collectException({ logError(e.toString); writeln(e.toString()); }());
        exit(-1);
    }

    if (response !is null)
    {
        /**
		CORS support
		http://www.cnblogs.com/feihong84/p/5678895.html
		https://stackoverflow.com/questions/10093053/add-header-in-ajax-request-with-jquery
		*/

        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "*");

        response.setHeader("Access-Control-Allow-Headers",
                "DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type");
        if (response.dataHandler is null)
            response.dataHandler = req.responseHandler;

        collectException(() { response.done(); response.clear(); }());
    }
}
