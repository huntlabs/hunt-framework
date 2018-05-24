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

module app.controller.index;

import hunt;

import app.middleware.auth;

class IndexController : Controller
{
	mixin MakeController;

    @Action
    void index()
    {
        response.html("Welcome to this example website.");
    }

    @Action
    void show()
	{
        response.html("this is show page.");
    }

    @Action
    @Middleware("AuthMiddleware")
    void allowed()
    {
        response.html("You are allowed.");
    }
}
