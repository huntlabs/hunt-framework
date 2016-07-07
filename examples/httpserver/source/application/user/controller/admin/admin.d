module application.user.controller.admin.admin;

import hunt.application;

class AdminController : Controller
{
    mixin HuntDynamicCallFun;
    
    void show()
    {
    	alias res = this.response;

        res.setContext("<h2>"~"line:"~__LINE__~",function:"~__FUNCTION__);
        res.setHeader("content-type","text/html;charset=UTF-8");
		res.done();
    }
}
