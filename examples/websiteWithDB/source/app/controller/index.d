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
import hunt.application;
import db;
import app.config;
import std.random;

class IndexController : Controller
{
	mixin MakeController;
    this()
    {
    }

	@Action void dbset()
	{
		string str = uniform(0, 100).to!int.to!string;
		string sql = `insert into user(username) values("`~str~`");`;
		ddo.execute(sql);
		response.html(str);
	}
	@Action void dbget()
	{
		string str = uniform(0, 100).to!int.to!string;
		Statement statement = ddo.query("SELECT * FROM user where username = '"~str~"' limit 10");
		ResultSet rs = statement.fetchAll();
		response.html(str);
	}
}
