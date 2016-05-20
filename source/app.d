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

void hello(Request, Response res)
{
    res.setContext("hello world");
    res.setHeader("content-type","text/html;charset=UTF-8");
    res.done();
}

void show()
{
    import hunt.web.view;
    import display = hunt.web.view.display;
    auto ctx = new TempleContext;
    ctx.name = "viile";

    display.layouts_main.layout(&display.hello).render(function(str) {
        write(str);
    }, ctx);

}
void main()
{
    writeln("hello world");
    //globalLogLevel(LogLevel.error);
    WebApplication app = new WebApplication();

    app.setGroupRouterConfig(new ConfigParse("config/router.conf", "config/application.conf"));
    //app.addRouter("GET","/test",toDelegate(&hello)).addRouter("GET","/ttt",toDelegate(&hello));
    //app.setGlobalAfterPipelineFactory(new GAMFactory).setGlobalBeforePipelineFactory(new GBMFactory);
    app.group(new EventLoopGroup(1)).bind(8080);

    app.run();
}
