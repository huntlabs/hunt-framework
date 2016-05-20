/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */
module application.middleware;

import std.functional;

import hunt.web.http;
import hunt.web.http.request;
import hunt.web.http.response;

class BMiddleWare : MiddleWare
{
    override void handle(Context ctx, Request req, Response res)
    {
        res.setContext("<H3>befor MiddleWare BMiddleWare</H3> <br/>");
        ctx.next(req,res);
    }
}

class AMiddleWare : MiddleWare
{
    override void handle(Context ctx, Request req, Response res)
    {
        res.setContext("<H3>after MiddleWare BMiddleWare</H3> <br/>");
        ctx.next(req,res);
    }
}

class GBMiddleWare : MiddleWare
{
    override void handle(Context ctx, Request req, Response res)
    {
        res.setContext("<H1>Global befor MiddleWare BMiddleWare</H1> <br/>");
        ctx.next(req,res);
    }
}

class GAMiddleWare : MiddleWare
{
    override void handle(Context ctx, Request req, Response res)
    {
        res.setContext("<H1>Global after MiddleWare BMiddleWare</H1> <br/>");
        ctx.next(req,res);
    }
}

class EndMiddleWare : MiddleWare
{
    override void handle(Context ctx, Request req, Response res)
    {
        res.done();
    }
}

void GBMiddleWareFun(Request req, Response res)
{
    res.setContext("<H2>Global befor MiddleWare MiddleWareFunction</H2> <br/>");
}

void GAMiddleWareFun(Request req, Response res)
{
    res.setContext("<H2>Global after MiddleWare MiddleWareFunction</H2> <br/>");
}

class GBMFactory : RouterPipelineFactory
{
    override RouterPipeline newPipeline()
    {
        RouterPipeline pipe = new RouterPipeline();
        pipe.addHandler(new GBMiddleWare);
        pipe.addHandler(toDelegate(&GBMiddleWareFun));
        return pipe;
    }
}

class GAMFactory : RouterPipelineFactory
{
    override RouterPipeline newPipeline()
    {
        RouterPipeline pipe = new RouterPipeline();
        pipe.addHandler(new GAMiddleWare);
        pipe.addHandler(toDelegate(&GAMiddleWareFun));
        pipe.addHandler(new EndMiddleWare);
        return pipe;
    }
}
