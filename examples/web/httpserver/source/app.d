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
import std.stdio;
import std.functional;
import std.experimental.logger;

import hunt.web;

import hunt.server.http;
import application.middleware;

import collie.socket;

void hello(Request, Response res)
{
    res.setContext("hello world");
    res.setHeader("content-type","text/html;charset=UTF-8");
    res.done();
}

void test(Request, Response res)
{
    res.redirect("hello");
}

void main()
{
    writeln("hello world");
   // globalLogLevel(LogLevel.error);
    EventLoop loop = new EventLoop();
    
    HTTPServer app = new HTTPServer(loop);

    app.setRouterConfig(new ConfigSignalModule("config/router.conf"));
   //app.setRouterConfig(new ConfigSignalModule("config/router.api.conf"));
    app.addRouter("GET","/test",toDelegate(&test)).addRouter("GET","/hello",toDelegate(&hello));
    //app.setGlobalAfterPipelineFactory(new GAMFactory).setGlobalBeforePipelineFactory(new GBMFactory);
    app.group(new EventLoopGroup());
    app.bind(8080);

    
    app.run();
}
