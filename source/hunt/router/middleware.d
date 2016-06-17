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
module hunt.router.middleware;

import std.concurrency;

import hunt.routing.middleware;
import hunt.http.request;
import hunt.http.response;

alias MiddleWare = IMiddleWare!(Request, Response);
alias RouterPipeline = PipelineImpl!(Request, Response);
alias RouterPipelineFactory = IPipelineFactory!(Request, Response);

class MiddleWareDone : MiddleWare
{
    override void handle(Context ctx, Request req, Response res)
    {
        res.done();
    }
}

class MiddleWareHandleInFiber : MiddleWare
{
    override void handle(Context ctx, Request req, Response res)
    {
        _secheduler.start(delegate(){ctx.next(req,res);});
    }
    
private:
    static FiberScheduler _secheduler;
    static this()
    {
        _secheduler = new FiberScheduler;
    }
}


class FiberHandlePipelineFactory : RouterPipelineFactory
{
    override RouterPipeline newPipeline()
    {
        RouterPipeline pipe = new RouterPipeline();
        pipe.addHandler(new MiddleWareHandleInFiber());
        return pipe;
    }
}

class AfterDonePipelineFactory : RouterPipelineFactory
{
    override RouterPipeline newPipeline()
    {
        RouterPipeline pipe = new RouterPipeline();
        pipe.addHandler(new MiddleWareDone());
        return pipe;
    }
}
