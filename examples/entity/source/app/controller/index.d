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
	
    this()
    {
    }
  
    @Action
    void index()
    {
        this.response.html("list");
    }

    @Action
    void showbool()
    {
        import std.conv;
        import std.datetime : StopWatch;

        EntityManager entitymanager = entityManagerFactory.createEntityManager!(User);
        
    }
}
