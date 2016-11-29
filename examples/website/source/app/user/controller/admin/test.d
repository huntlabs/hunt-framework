module app.user.controller.admin.test;

import hunt.router;


class Test
{
	pragma(msg,_createRouterCallActionFun!(Test,false)());
	mixin BuildRouterFunction!(typeof(this));

	@Action("get","/testclass")
	void doReuest(Request req)
	{
		Response res = req.createResponse();
		res.setContext("this is in class Test!!");
		res.done();
	}
}

