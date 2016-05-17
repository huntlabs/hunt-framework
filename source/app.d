import std.stdio;
import std.functional;
import std.experimental.logger;

import hunt.web.http.cookie;

import hunt.web.webapplication;
import application.middleware;

void hello(Request, Response res)
{
    res.setContext("hello world");
    res.setHeader("content-type","text/html;charset=UTF-8");
}

void main()
{
    writeln("hello world");
    globalLogLevel(LogLevel.error);
    WebApplication app = new WebApplication();
    app.setRouterConfig(new ConfigParse("config/router.conf"));
    app.addRouter("GET","/test",toDelegate(&hello)).addRouter("GET","/ttt",toDelegate(&hello));
    app.setGlobalAfterPipelineFactory(new GAMFactory).setGlobalBeforePipelineFactory(new GBMFactory);
    app.group(new EventLoopGroup()).bind(8080);
    app.run();
}


