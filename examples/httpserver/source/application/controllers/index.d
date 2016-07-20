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
    this()
    {
        this.addMiddleware(new BeforeMiddleware());
    }
    override bool before()
    {
        this.response.html("<h3>before...</h3>");
        return true;
    }
    override bool after()
    {
        this.response.html("<h3>after...</h3>");
        return true;
    }
    mixin MakeController;
    @action
    @middleware(BeforeMiddleware.stringof)
    @middleware(AfterMiddleware.stringof)
    void show()
    {
        this.response.html("hello world<br/>")
        //.setHeader("content-type","text/html;charset=UTF-8")
        .setCookie("name", "value", 10000)
        .setCookie("name1", "value", 10000, "/path")
        .setCookie("name2", "value", 10000);
      //  auto model = new IndexModel();
        //model.showTest2();
    }
    @action
    @middleware(OneMiddleware.stringof)
    void list()
    {
		this.view.setLayout!"layouts/main.dhtml"();	
		this.view.test = "viile";
		this.view.username = "viile";
		this.view.header = "donglei header";
		this.view.footer = "footer";
		this.render!"content.dhtml"();
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
