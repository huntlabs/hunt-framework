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

module hunt.application.dispatcher;

import hunt.routing;
import hunt.http.request;
import hunt.http.response;
import hunt.application.controller;

import collie.utils.exception;
import collie.codec.http;

import std.exception;

import std.parallelism;

class Dispatcher
{
    this()
    {
        this._router = new Router;
    }

    public
    {
        void dispatch(Request request) nothrow
        {
            try
            {
                Route route;

                string cacheKey = request.header(HTTPHeaderCode.HOST) ~ "_" ~ request.method ~ "_" ~ request.path;

                route = this._cached.get(cacheKey, null);

                if (route is null)
                {
                    route = this._router.match(request.header(HTTPHeaderCode.HOST), request.method, request.path);
                    
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

                // add handle task to taskPool
                this._taskPool.put(task!doRequestHandle(route.handle, request));

            }
            catch(Exception e)
            {
                showException(e);
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

void doRequestHandle(HandleFunction handle, Request request)
{
    import hunt.http.exception;

    try
    {
        handle(request);
    }
    catch (CreateResponseException e)
    {
        showException(e);
    }
    catch (Exception e)
    {
        showException(e);
        
        Response response;

        collectException(request.createResponse, response);
        
        if(response)
        {
            collectException((){
                    response.setHttpStatusCode(502);
                    response.setContext(e.toString());
                    response.connectionClose();
                    response.done();
                }());
        }
    }
    catch (Error e)
    {
        import std.stdio : writeln;

        collectException({error(e.toString); writeln(e.toString());}());

        import core.stdc.stdlib : exit;

        exit(-1);
    }
}
