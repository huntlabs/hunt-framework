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
import std.experimental.logger;
import std.stdio;

import std.json;

version(USE_ENTITY) import app.model.index;

class IpFilterMiddleware : IMiddleware{

	override string name() {
		return IpFilterMiddleware.stringof;
	}
	override Response onProcess(Request req,Response res) {
		writeln(req.getSession());
		return null;
	}
}

class IndexController : Controller
{
	mixin MakeController;
	this()
	{
		this.addMiddleware(new IpFilterMiddleware());
	}

	@Action
	string helloworld()
	{
		return "hello world!";
	}

	@Action
	int hello123()
	{
		return 123;
	}

	@Action
	JSONValue hellojson()
	{
		JSONValue j = [ "hello": "json" ];

		return j;
	}

	@Action
	Reponse hello()
	{
		response.setContent("hello");

		return response;
	}

	@Action
		Response show()
		{	
			auto response = this.request.createResponse();
			response.html("hello world<br/>")
				//.setHeader("content-type","text/html;charset=UTF-8")
				.setCookie("name", "value", 10000)
				.setCookie("name1", "value", 10000, "/path")
				.setCookie("name2", "value", 10000);

			response.done();
			return response;			
		}
	@Action
		Response  list()
		{
			this.view.setLayout!"main.dhtml"();	
			this.view.test = "viile";
			this.view.username = "viile";
			this.view.header = "donglei header";
			this.view.footer = "footer";
			this.render!"content.dhtml"();
			return response;
		}
	@Action
		Response  index()
		{
			this.response.html("list");
			return response;
		}

	@Action
		Response  showbool()
		{
			trace("---show bool----");
			this.response.html("list");
			return response;
		}
	@Action Response  setCache()
	{
		session.set("test","test");
		//auto key = request.get("key");	
		//auto value = request.get("value");	
		//cache.set(key,value);
		auto response = this.request.createResponse();
		//response.html("key : " ~ key ~ " value : " ~ value);
		response.html(session.sessionId);
		return response;
	}
	@Action Response  getCache()
	{
		//auto key = request.get("key");	
		//auto value = cache.get(key);
		auto response = this.request.createResponse();
		//response.html(session.get("test") ~ " key : " ~ key ~ " value : " ~ value);
		response.html(session.get("test"));
		return response;
	}
}
