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

module hunt.framework.application.dispatcher;

import hunt.framework.routing;
import hunt.framework.http.request;
import hunt.framework.http.response;
import hunt.framework.exception;

import hunt.framework.simplify;
import hunt.framework.application.controller;
import hunt.framework.application.config;

import hunt.framework.security.acl.Identity;
import hunt.framework.security.acl.Manager;
import hunt.framework.security.acl.User;

import hunt.http.codec.http.model.HttpHeader;
// import collie.utils.exception;
// import collie.codec.http;

import std.stdio;
import std.exception;
import std.parallelism;
import std.conv : to;

import hunt.logging;
import hunt.util.exception;

class Dispatcher
{
    this()
    {
        this._router = new Router;
        this._router.setConfigPath(Config.path);
    }

    void dispatch(Request request) nothrow
    {
        try
        {
            Route route;

            string cacheKey = request.header(
                    HttpHeader.HOST) ~ "_" ~ request.method ~ "_" ~ request.path;
            route = this._cached.get(cacheKey, null);

            /// init this thread request for error return.
            hunt.framework.http.request.request(request);

            if (route is null)
            {
                import std.array : split;
                string domain = split(request.header(HttpHeader.HOST), ":")[0];
                route = this._router.match(domain, request.method, request.path);

                if (route is null)
                {
                    auto response = request.getResponse();
                    response.do404();
                    // response.connectionClose();
                    response.done();
                    return;
                }

                this._cached[cacheKey] = route;
            }

            // add route's params
            auto params = route.getParams();
            if (params.length > 0)
            {
                implementationMissing(false);
                foreach (param, value; params)
                {
                    // request.Header().setQueryParam(param, value);
                    
                }
            }

            request.route = route;

            // hunt.security filter
            request.user = authenticateUser(request);

            if (!accessFilter(request))
            {
                auto response = request.getResponse();
                response.do403("no permiss to access: " ~ request.route.getController() ~ "." ~ request.route.getAction());
                // response.connectionClose();
                response.done();
                return;
            }

            // FIXME: Needing refactor or cleanup -@zxp at 9/14/2018, 5:17:25 PM
            version(NO_TASKPOOL)
            {
                doRequestHandle(route.handle, request);
            }
            else {
                // add handle task to taskPool
                this._taskPool.put(task!doRequestHandle(route.handle, request));
            }            
        }
        catch (Exception e)
        {
            collectException(error(e.toString));
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

    @property Router router()
    {
        return this._router;
    }

    private
    {
        Router _router;
        Route[string] _cached;
        TaskPool _taskPool;
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
            response = req.getResponse;
    }
    catch (CreateResponseException e)
    {
        collectException(error(e.toString));
    }
    catch (Exception e)
    {
        collectException(error(e.toString));
        response = req.getResponse;
        response.setStatus(502);
        response.setContent(e.toString());
        // response.connectionClose();
        response.close();
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
        // if (response.dataHandler is null)
        //     response.dataHandler = req.responseHandler;

        collectException(() { response.done(); }());
    }
}
