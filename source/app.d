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

import hunt.web.http.cookie;

import hunt.web.application;
import application.middleware;

import collie.socket;

void hello(Request, Response res)
{
    res.setContext("hello world");
    res.setHeader("content-type","text/html;charset=UTF-8");
    res.done();
}

void main()
{
    writeln("hello world");
   // globalLogLevel(LogLevel.error);
    EventLoop loop = new EventLoop();
    
    WebApplication app = new WebApplication(loop);

    app.setRouterConfig(new ConfigSignalModule("config/router.conf"));
   //app.setRouterConfig(new ConfigSignalModule("config/router.api.conf"));
    //app.addRouter("GET","/test",toDelegate(&hello)).addRouter("GET","/ttt",toDelegate(&hello));
    //app.setGlobalAfterPipelineFactory(new GAMFactory).setGlobalBeforePipelineFactory(new GBMFactory);
    app.group(new EventLoopGroup());
    app.bind(8080);

    
    app.run();
}
