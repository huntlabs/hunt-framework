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

module app.controller.admin.index;

import hunt;

class IndexController : Controller
{
	mixin MakeController;

    @Action
    void index()
	{ 
        response.html("ADMINCP..");
    }

    @Action
    void login()
    {
        response.html("LOGIN..");
    }
}
