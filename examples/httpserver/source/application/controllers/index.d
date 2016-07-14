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
import application.model.index;


class IndexController : Controller
{

    mixin MakeController;
    
    @action
    @middleware(BeforeWidget.stringof, AfterWidget.stringof)
    void show()
    {
        this.response.html("hello world 董磊<br/>")
        //.setHeader("content-type","text/html;charset=UTF-8")
        .setCookie("name", "value", 10000)
        .setCookie("name1", "value", 10000, "/path")
        .setCookie("name2", "value", 10000);
      //  auto model = new IndexModel();
        //model.showTest2();
    }

    @action
    @middleware("", OneWidget.stringof)
    void list()
    {
        this.response.html("list");
    }
    @action
    void index()
    {
        this.response.html("list");
    }
  
    @action
    void showbool()
    {
        this.response.html("list");
    }
  
}
