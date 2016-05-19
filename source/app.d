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
}

void show()
{
    import hunt.web.view;
    import hunt.web.view.display;
    auto ctx = new TempleContext;
    ctx.name = "viile";

    hunt.web.view.display.layouts_main.layout(&hunt.web.view.display.hello).render(function(str) {
        write(str);
    }, ctx);

}
void main()
{
    writeln("hello world");
    //globalLogLevel(LogLevej.error);
    WebApplication app = new WebApplication();
    app.setGroupRouterConfig(new ConfigParse("config/router.conf", "config/application.conf"));
    //app.addRouter("GET","/test",toDelegate(&hello)).addRouter("GET","/ttt",toDelegate(&hello));
    app.setGlobalAfterPipelineFactory(new GAMFactory).setGlobalBeforePipelineFactory(new GBMFactory);
    app.group(new EventLoopGroup()).bind(8080);
    app.run();
}


