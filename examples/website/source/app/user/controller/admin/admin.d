module app.user.controller.admin.admin;

import hunt.application;

class AdminController : Controller
{
    mixin MakeController;
    
    @action
    void show()
    {
    	alias res = this.response;

        res.html("<h2>"~"line:"~__LINE__~",function:"~__FUNCTION__);
    }
}
