module application.controllers.index;

import hunt.http.controller;
import hunt.http.request;
import hunt.http.response;

class IndexController : IController
{
    mixin HuntDynamicCallFun;
    
    void show(Request req, Response res)
    {
        import std.stdio;
        writeln("do show!");
        res.setContext("hello world");
        res.setHeader("content-type","text/html;charset=UTF-8");
        res.done();
    }
}
