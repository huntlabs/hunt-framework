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
import hunt.orm.entity;
import entity;

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
		UserDao.registerUser();
    }
}
