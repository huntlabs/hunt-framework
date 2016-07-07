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
module application.controllers.index;

import hunt.application;

class IndexController : Controller
{
    mixin HuntDynamicCallFun;
    
    //void show(Request req, Response res)
    void show()
    {
        import std.stdio;
        writeln("do show!");
        this.response.setContext("hello world<br/>");
        this.response.setHeader("content-type","text/html;charset=UTF-8");
		this.response.done();
    }
    
}
