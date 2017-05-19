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

import app.service.user;

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
        
        StopWatch sw;
        sw.start();
        auto vid = UserService.registerUser();
        sw.stop();
        
        this.response.html("id is :" ~to!string(sw.peek().msecs));
    
        sw.reset();
        sw.start();
        UserService.updateUserName(vid, "dl_" ~to!string(vid));
        sw.stop();
        
        this.response.html("id is :" ~to!string(sw.peek().msecs));

        sw.reset();
        sw.start();
        UserService.getUserName(10);
        sw.stop();

        this.response.html("id is :" ~to!string(sw.peek().msecs));
    }
}
