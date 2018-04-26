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

version (USE_ENTITY) import app.model.index;

class IndexController : Controller
{
	mixin MakeController;
	this()
	{
	}

	@Action void show()
	{
		auto response = this.request.createResponse();
		response.html("hello world<br/>") //.setHeader("content-type","text/html;charset=UTF-8")
		.setCookie("name", "value", 10000)
		.setCookie("name1", "value", 10000, "/path")
		.setCookie("name2", "value", 10000);
	}

	@Action void list()
	{
		this.view.setLayout!"main.dhtml"();
		this.view.test = "viile";
		this.view.username = "viile";
		this.view.header = "donglei header";
		this.view.footer = "footer";
		this.render!"content.dhtml"();

	}

	@Action void index()
	{
		// this.response.html("list");
		show();
	}

	@Action void upload()
	{
		import std.stdio;

		auto test = request.file("test");
		if (test is null)
		{
			this.response.html("upload error");
			return;
		}
		writeln(test.fileName);
		writeln(test.fileSize);
		writeln(test.contentType);
		ubyte[] rdata;
		test.read(test.fileSize, (in ubyte[] data) { rdata ~= data; });
		this.response.html(test.fileName);
	}

	@Action void download()
	{
		this.response.download("test", cast(ubyte[]) "test");
	}

	@Action void showbool()
	{
		trace("---show bool----");
		this.response.html("list");
	}

	@Action void setCache()
	{
		auto key = request.get("key");
		auto value = request.get("value");
		cache.put(key, value);
		auto response = this.request.createResponse();
		response.html("key : " ~ key ~ " value : " ~ value);
	}

	@Action void getCache()
	{
		auto key = request.get("key");
		auto value = cast(string) cache.get!string(key);
		auto response = this.request.createResponse();
		response.html("key : " ~ key ~ " value : " ~ value);
	}
}
