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
module app.user.controller.admin.index;

import hunt.application;

class IndexController : Controller!IndexController
{
    @Action
    void show()
    {
		auto res = this.request.createResponse();
        res.html("hello world<br/>"~__FUNCTION__);
    }
}
