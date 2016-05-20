module application.user.controller.admin.index;

import hunt.web.http;

class IndexController : IController
{
    mixin HuntDynamicCallFun;
    
    void show(Request req, Response res)
    {
        import std.stdio;
        writeln("doxxxx show!");
        res.setContext("hello world<br/>");
        res.setHeader("content-type","text/html;charset=UTF-8");
	res.done();
    }
}
