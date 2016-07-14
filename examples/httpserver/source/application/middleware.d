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
module application.middleware;

import std.functional;

import hunt.application;
import hunt.router;


class MiddlewareFactory : AbstractMiddlewareFactory
{
    override IMiddleware[] getMiddlewares()
    {
        IMiddleware[] _list;
        _list ~= new OneWidget();
        _list ~= new TwoWidget();
       return _list;
    }
}

class OneWidget : IMiddleware
{
    override bool onProcess(Request req, Response res)
    {
        res.setContext("<H1>One....</H1> <br/>");
        return true;
    }
}

class TwoWidget : IMiddleware
{
    override bool onProcess(Request req, Response res)
    {
        res.setContext("<H1>Two....</H1> <br/>");
        return true;
    }
}


class BeforeWidget : IMiddleware
{
    override bool onProcess(Request req, Response res)
    {
        res.setContext("<H1>BeforeWidget....</H1> <br/>");
        return true;
    }
}

class AfterWidget : IMiddleware
{
    override bool onProcess(Request req, Response res)
    {
        res.setContext("<H1>AfterWidget....</H1> <br/>");
        return true;
    }
}
