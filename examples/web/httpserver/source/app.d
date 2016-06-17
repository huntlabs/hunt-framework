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

import hunt.application;
import application.middleware;

import collie.socket;

void hello(Request, Response res)
{
    res.setContext("hello world");
    res.setHeader("content-type","text/html;charset=UTF-8");
    res.done();
}

void test(Request, Response res)
{
    res.redirect("hello");
}

static this()
{
    auto app = WebApplication.app();
    app.addRouter("GET","/test",toDelegate(&test)).addRouter("GET","/hello",toDelegate(&hello));
}

