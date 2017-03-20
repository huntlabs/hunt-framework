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

import hunt;

import std.experimental.logger;

import app.middleware;

version(USE_ENTITY) import app.model.index;

class IndexController : Controller
{
	mixin MakeController;
    this()
    {
        this.addMiddleware(new BeforeMiddleware());
    }
  
	@Action
    void index()
    {
        this.response.html("list");
    }

	@Action
    void showbool()
    {
	import app.dao.user;
	import std.conv;
	import std.datetime;
	StopWatch sw;
		sw.start();
	auto vid = UserDao.registerUser();
		sw.stop();
		this.response.html("id is :" ~to!string(sw.peek().msecs));
	
		sw.reset();
		sw.start();
	UserDao.updateUserName(vid, "dl_" ~to!string(vid));
		sw.stop();
		this.response.html("id is :" ~to!string(sw.peek().msecs));

		sw.reset();
		sw.start();
		UserDao.getUserName(10);
		sw.stop();

		this.response.html("id is :" ~to!string(sw.peek().msecs));
    }
}
