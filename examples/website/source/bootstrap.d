/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */

import std.stdio;
import std.functional;
import std.experimental.logger;

/* use hunt framework */
import hunt;

import app.middleware;
import hunt.i18n;

void hello(Request req)
{
	Response res = req.createResponse();
	res.html("hello world");
	res.done();
}

void test(Request req)
{

	import app.controller.index;
	auto test = new IndexController();
	test.__CALLACTION__("show",req);
	Response res = req.createResponse();
	//res.redirect("/");
	res.done();
}

void main()
{

	auto app = Application.getInstance();
	app.addRoute("GET","/test",&test).addRoute("GET","/",&hello);
	//.setMiddlewareFactory(new MiddlewareFactory())
	//.enableLocale();

	app.addRoute("GET","/label/edit/{id:[0-9]*}",&hello);

	///设置语言
	setLocale("en-br");
	writeln( getText("message.hello-world"));

	///设置语言
	setLocale("zh-cn");
	writeln( getText("email.subject"));

	///设置语言
	setLocale("en-us");
	writeln( getText("email.subject", "empty"));

	app.setRedis("127.0.0.1",6379);
	app.setMemcache("127.0.0.1",11211);
	writeln(Redis.set("hello","world"));
	writeln(Memcache.set("hello","world"));

	app.run();
}

