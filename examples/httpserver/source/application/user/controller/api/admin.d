module application.user.controller.api.admin;

import hunt.application;

class AdminController : Controller
{
    mixin ControllerInCompileTime;
    @action
    void show()
    {
    	alias res = this.response;
        res.html("<h2>"~"line:"~__LINE__~",function:"~__FUNCTION__);
    }
}
