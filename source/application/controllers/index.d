module application.controllers.index;

import hunt.http;

class IndexController : IController
{
    mixin HuntDynamicCallFun;
    
    void show(Request req, Response res)
    {
        import std.stdio;
       // writeln("do show!");
        res.setContext("hello world<br/>");
        res.setHeader("content-type","text/html;charset=UTF-8");
    }
}
