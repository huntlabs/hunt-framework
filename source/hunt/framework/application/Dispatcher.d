/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.application.Dispatcher;

import hunt.framework.application.Controller;
import hunt.framework.application.ApplicationConfig;
import hunt.framework.Exceptions;
import hunt.framework.http.Request;
import hunt.framework.http.Response;
import hunt.framework.routing;
import hunt.framework.security.acl.Manager;
import hunt.framework.security.acl.User;
import hunt.framework.Simplify;
import hunt.framework.trace.Tracer;

import hunt.logging;
import hunt.Exceptions;
import hunt.http.codec.http.model.HttpHeader;

import std.stdio;
import std.exception;
import std.parallelism;
import std.conv : to;

class Dispatcher
{
    this()
    {
        this._router = new Router;
        this._router.setConfigPath(DEFAULT_CONFIG_PATH);
    }

    void dispatch(Request request) nothrow
    {
        try
        {
            Route route;

            string cacheKey = request.header(
                    HttpHeader.HOST) ~ "_" ~ request.methodAsString ~ "_" ~ request.path;
            route = this._cached.get(cacheKey, null);

            /// init this thread request for error return.
            hunt.framework.http.Request.request(request);

            if (route is null)
            {
                import std.array : split;
                string domain = split(request.header(HttpHeader.HOST), ":")[0];
                route = this._router.match(domain, request.methodAsString, request.path);

                if (route is null)
                {
                    auto response = new Response(request);
                    response.do404();
                    // response.connectionClose();
                    response.done();
                    return;
                }

                this._cached[cacheKey] = route;
            }

            // add route's params
            auto params = route.getParams();
            foreach (param, value; params)
            {
                // tracef("param=%s, value=%s", param, value);
                request.putQueryParameter(param, value);
            }

            request.route = route;

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

Response doGroupMiddleware(Request request)
{
    if (request.route.getController().length == 0)
        return null;

    auto mids = app().getGroupMiddlewares(request.route.getGroup());
    if( mids.length == 0)
        return null;

    string mca = request.getMCA();

    if(mca == "hunt.application.staticfile.staticfile.doStaticFile" ||
        mca == "staticfile.doStaticFile" )
        return null;

    Response response;
    foreach(m ; mids)
    {
        response = m.onProcess(request , response);
        if(response !is null)
            return response;
    }
    return null;
}

void doRequestHandle(RoutingHandler handle, Request req)
{
    Response response;

    // this thread _request
    request(req);
    newFrameworkTrace(req);
    try
    {
        ///this group middleware.
        response = doGroupMiddleware(req);
        if(response is null)
        {


            response = handle(req);

            if (response is null)
                response = new Response(req);
        }
        finishFrameworkTrace(response);
    }
    catch (CreateResponseException e)
    {
        finishFrameworkTrace(e.toString);
        collectException(error(e.toString));
    }
    catch (Exception e)
    {
        collectException(error(e.toString));
        response = new Response(req);
        response.setStatus(502);
        response.setContent(e.toString());
        finishFrameworkTrace(response);
        // response.connectionClose();
        response.close();
    }
    catch (Error e)
    {
        import std.stdio : writeln;
        import core.stdc.stdlib : exit;
        finishFrameworkTrace(e.toString);
        collectException({ logError(e.toString);
            writeln(e.toString()); 
        }());
        exit(-1);
    }

    if (response !is null)
    {
        /**
        CORS support
        http://www.cnblogs.com/feihong84/p/5678895.html
        https://stackoverflow.com/questions/10093053/add-header-in-ajax-request-with-jquery
        */
        ApplicationConfig.HttpConf httpConf = config().http;
        if(httpConf.enableCors) {
            response.setHeader("Access-Control-Allow-Origin", httpConf.allowOrigin);
            response.setHeader("Access-Control-Allow-Methods", httpConf.allowMethods);
            response.setHeader("Access-Control-Allow-Headers", httpConf.allowHeaders);
        }
        // if (response.dataHandler is null)
        //     response.dataHandler = req.responseHandler;

        collectException(() { response.done(); }());
    }
}
