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
module app.user.controller.admin.index;

import hunt.application;

class IndexController : Controller
{
	mixin MakeController;

    @Action
    void show()
    {
		auto res = this.request.createResponse();
        res.html("hello world<br/>"~__FUNCTION__);
    }
}
