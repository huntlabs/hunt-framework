/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
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
