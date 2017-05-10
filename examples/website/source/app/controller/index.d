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
module app.controller.index;
import hunt.application;
public import app.middleware;
import std.experimental.logger;

version(USE_ENTITY) import app.model.index;

class IndexController : Controller
{
	mixin MakeController;
    this()
    {
        this.addMiddleware(new BeforeMiddleware());
    }
    override bool before()
    {
		trace("before-----");
        this.response.html("<h3>before...</h3>");
		trace("before-----offiter");
        return true;
    }
    override bool after()
    {
        this.response.html("<h3>after...</h3>");
        return true;
    }
    @Action
    @Middleware(BeforeMiddleware.stringof)
    @Middleware(AfterMiddleware.stringof)
    void show()
	{ 
		auto response = this.request.createResponse();
        response.html("hello world<br/>")
        //.setHeader("content-type","text/html;charset=UTF-8")
        .setCookie("name", "value", 10000)
        .setCookie("name1", "value", 10000, "/path")
        .setCookie("name2", "value", 10000);
    }
	@Action
    @Middleware(OneMiddleware.stringof)
    void list()
    {
		this.view.setLayout!"main.dhtml"();	
		this.view.test = "viile";
		this.view.username = "viile";
		this.view.header = "donglei header";
		this.view.footer = "footer";
		this.render!"content.dhtml"();

    }
	@Action
    void index()
    {
        this.response.html("list");
    }

	@Action
    void showbool()
    {
		trace("---show bool----");
        this.response.html("list");
    }
	@Action void setCache()
	{
		auto key = request.get("key");	
		auto value = request.get("value");	
		cache.set(key,value);
		auto response = this.request.createResponse();
        response.html("key : " ~ key ~ " value : " ~ value);
	}
	@Action void getCache()
	{
		auto key = request.get("key");	
		auto value = cache.get(key);
		auto response = this.request.createResponse();
        response.html("key : " ~ key ~ " value : " ~ value);
	}
}
