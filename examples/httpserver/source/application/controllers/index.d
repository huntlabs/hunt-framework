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
import application.middleware;


class IndexController : Controller
{
    mixin ControllerInCompileTime;
    
    @action
    @widget(BeforeWidget.stringof, AfterWidget.stringof)
    void show()
    {
        this.response.html("hello world 董磊<br/>")
        //.setHeader("content-type","text/html;charset=UTF-8")
        .setCookie("name", "value", 10000)
        .setCookie("name1", "value", 10000, "/path")
        .setCookie("name2", "value", 10000);
    }

    @action
    @widget("", OneWidget.stringof)
    string list()
    {
    	return "list";
    }
    @action
    void index()
    {
        writeln("do index!");
    	return ;
    }
  
    @action
    auto showbool()
    {
    	writeln("show bool");
    	return true;
    }
  
}
