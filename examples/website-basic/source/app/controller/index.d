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
import hunt.view;

import core.time;

import std.array;
import std.experimental.logger;
import std.stdio;
import std.datetime;
import std.json;

version (USE_ENTITY) import app.model.index;

class IpFilterMiddleware : MiddlewareInterface
{

	override string name()
	{
		return IpFilterMiddleware.stringof;
	}

	override Response onProcess(Request req, Response res)
	{
		writeln(req.session());
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

	override bool before()
	{
		/**
		CORS support
		http://www.cnblogs.com/feihong84/p/5678895.html
		https://stackoverflow.com/questions/10093053/add-header-in-ajax-request-with-jquery
		*/

		// FIXME: Needing refactor or cleanup -@zxp at 5/10/2018, 11:33:11 AM
		// set this through the configuration
		response.setHeader("Access-Control-Allow-Origin", "*");
		response.setHeader("Access-Control-Allow-Methods", "*");
		response.setHeader("Access-Control-Allow-Headers", "*");

		if (cmp(toUpper(request.method), "OPTIONS") == 0)
		{
			return false;
		}

		return true;
	}

	@Action string index()
	{
		Appender!string stringBuilder;
		stringBuilder.put("Hello world!<br/>");
		stringBuilder.put("The time now is " ~ Clock.currTime.toString());
		stringBuilder.put("<br/>");
		stringBuilder.put("Test links:<br/>");
		stringBuilder.put(`<a href="/show">show Response</a><br/>`);
		stringBuilder.put(`<a href="/showvoid">show void</a><br/>`);
		stringBuilder.put(`<a href="/showString">show string</a><br/>`);
		stringBuilder.put(`<a href="/showBool">show bool</a><br/>`);
		stringBuilder.put(`<a href="/showInt">show int</a><br/>`);
		stringBuilder.put(`<a href="/showJson">show json</a><br/><br/>`);
		stringBuilder.put(`<a href="/set?key=company&value=Putao">set Cache</a><br/>`);
		stringBuilder.put(`<a href="/get?key=company">get Cache (Use Postman with cookie set)</a><br/>`);

		// this.response.html(stringBuilder.data);

		JSONValue data;
		data["title"] = "Hunt demo";
		data["now"] = Clock.currTime.toString();

		string r = Env().render_file("home.dhtml", data);

		return r;
	}

	Response showAction()
	{
		trace("---show Action----");
		// dfmt off
		auto response = this.request.createResponse();
		response.html("Show message(No @Action defined): Hello world<br/>")
		.setCookie("name", "value", 10000)
		.setCookie("name1", "value", 10000, "/path")
		.setCookie("name2", "value", 10000);
		// dfmt on
		return response;
	}

	Response test_action()
	{
		trace("---test_action----");
		// dfmt off
		response.html("Show message: Hello world<br/>")
		.setCookie("name", "value", 10000)
		.setCookie("name1", "value", 10000, "/path")
		.setCookie("name2", "value", 10000);
		// dfmt on

		return response;
	}

	@Action void showVoid()
	{
		trace("---show void----");
	}

	@Action string showString()
	{
		trace("---show string----");
		return "Hello world.";
	}

	@Action bool showBool()
	{
		trace("---show bool----");
		return true;
	}

	@Action int showInt()
	{
		trace("---show bool----");
		return 2018;
	}

	@Action JSONValue showJson()
	{
		trace("---show Json----");
		JSONValue js;
		js["message"] = "Hello world.";
		return js;
	}

	@Action string showView()
	{
		JSONValue data;
		data["name"] = "Cree";
		data["alias"] = "Cree";
		data["city"] = "Christchurch";
		data["age"] = 3;
		data["age1"] = 28;
		data["addrs"] = ["ShangHai", "BeiJing"];
		data["is_happy"] = false;
		data["allow"] = false;
		data["users"] = ["name" : "jeck", "age" : "18"];
		data["nums"] = [3, 5, 2, 1];

		string r = Env().render_file("index.txt", data);

		return r;
	}

	@Action Response setCache()
	{
		Session session = request.session();
		session.set("test", "current value");

		string key = request.get("key");	
		string value = request.get("value");	
		cache.put(key,value);

		Appender!string stringBuilder;

		stringBuilder.put("Cache test: <br/>");
		stringBuilder.put("key : " ~ key ~ " value : " ~ value);
		stringBuilder.put("<br/><br/>Session Test: ");
		stringBuilder.put("<br/>SessionId: " ~ session.sessionId);
		stringBuilder.put("<br/>key: test, value: " ~ session.get("test"));

		Response response = this.request.createResponse();
		response.html(stringBuilder.data);
		return response;
	}
	
	@Action Response getCache()
	{
		Session session = request.session();
		string sessionValue = session.get("test");

		string key = request.get("key");	
		string value = cache.get!(string)(key);

		Appender!string stringBuilder;
		stringBuilder.put("Cache test:<br/>");
		stringBuilder.put(" key: " ~ key ~ ", value: " ~ value);
		
		stringBuilder.put("<br/><br/>Session Test: ");
		stringBuilder.put("<br/>  SessionId: " ~ session.sessionId);
		stringBuilder.put("<br/>  key: test, value: " ~ sessionValue);

		Response response = this.request.createResponse();
		response.html(stringBuilder.data);

		return response;
	}
}
