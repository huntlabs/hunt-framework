module app.user.controller.admin.admin;

import hunt.application;

class AdminController : Controller
{
    mixin MakeController;
    
    @Action()
    void show()
    {
		auto res = this.request.createResponse();

        res.html("<h2>"~"line:"~__LINE__~",function:"~__FUNCTION__);
    }
}
