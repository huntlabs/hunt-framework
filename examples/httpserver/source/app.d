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
}

