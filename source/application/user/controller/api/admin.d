module application.user.controller.api.admin;

import hunt.web.http;

class AdminController : IController
{
    mixin HuntDynamicCallFun;
    
    void show(Request req, Response res)
    {
        res.setContext("<h2>"~"line:"~__LINE__~",function:"~__FUNCTION__);
        res.setHeader("content-type","text/html;charset=UTF-8");
	res.done();
    }
}
