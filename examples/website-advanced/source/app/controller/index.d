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

class IndexController : Controller
{
	mixin MakeController;

    @Action
    void index()
    {
	cache.set("a", "A");
    	    response.html("Welcome to this example website." ~ cache.get("a"));
    }

    @Action
    void show()
	{
        response.html("this is show page." ~ cache.get("a"));
    }
}
