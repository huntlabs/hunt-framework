module app.user.controller.admin.test;

import hunt.router;


class Test
{
	mixin BuildRouterFunction!(typeof(this));

	@Action("/testclass")
	void doReuest(Request req)
	{
		Response res = req.createResponse();
		res.setContext("this is in class Test!!");
		res.done();
	}
}

