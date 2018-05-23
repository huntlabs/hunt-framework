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

/* use hunt framework */
import hunt;

import hunt.i18n;

void hello(Request req)
{
	Response res = req.createResponse();
	res.html("hello world");
	res.done();
}

void main()
{

	auto app = Application.getInstance();
	app.addRoute("GET","/showuser",&hello);
	//.setMiddlewareFactory(new MiddlewareFactory())
	//.enableLocale();

	app.addRoute("GET","/label/edit/{id:[0-9]*}",&hello);

	//set language
	app.enableLocale();
	setLocale("en-br");
	writeln( getText("message.hello-world"));

	//set language
	setLocale("zh-cn");
	writeln( getText("email.subject"));

	//set language
	setLocale("en-us");
	writeln( getText("email.subject", "empty"));

	//Redis.set("hello","world");
	//Memcache.set("hello","world");
	//writeln(Redis.get("hello"),Memcache.get("hello"));

	app.run();
}

