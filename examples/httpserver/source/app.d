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

import application.middleware;
import hunt.i18n;

void hello(Request, Response res)
{
    res.html("hello world");
    res.done();
}

void test(Request, Response res)
{
    res.redirect("hello");
}

static this()
{
    auto app = Application.app();
    app.addRouter("GET","/test",toDelegate(&test)).addRouter("GET","/hello",toDelegate(&hello))
    .setMiddlewareFactory(new MiddlewareFactory());

    ///初始化资源
	I18n i18n = I18n.instance();
	i18n.loadLangResources("./resources/lang");
	
	
	///设置语言
	setLocal("en-br");
	writeln( getText("message.hello-world", "empty"));
	
	///设置语言
	setLocal("zh-cn");
	writeln( getText("email.subject", "empty"));
	
	///设置语言
	setLocal("en-us");
	writeln( getText("email.subject", "empty"));
}

