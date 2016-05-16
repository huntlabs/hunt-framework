import std.stdio;
import std.functional;

import hunt.http.cookie;

import hunt.webapplication;

void hello(Request, Response res)
{
    res.setContext("hello world");
    res.setHeader("content-type","text/html;charset=UTF-8");
    res.done();
}

void main()
{
    WebApplication app = new WebApplication();
    app.setRouterConfig(new ConfigParse("config/router.conf"));
    app.addRouter("GET","/test",toDelegate(&hello));
    app.addRouter("GET","/ttt",toDelegate(&hello));
    app.bind(8080);
    app.run();
}


