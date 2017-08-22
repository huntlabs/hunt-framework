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
 
import std.stdio;
import std.functional;
import std.experimental.logger;

import hunt;

void main()
{

    auto app = Application.getInstance();

	import app.model.user;
	registerEntity!(User,Blog);

	app.run();
}

