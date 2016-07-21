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
module app.middleware;

import std.functional;

import hunt.application;
import hunt.router;


class MiddlewareFactory : AbstractMiddlewareFactory
{
    override IMiddleware[] getMiddlewares()
    {
        IMiddleware[] _list;
        _list ~= new OneMiddleware();
        _list ~= new TwoMiddleware();
       return _list;
    }
}

class OneMiddleware : IMiddleware
{
    override string name()
    {
        return OneMiddleware.stringof;
    }
    override bool onProcess(Request req, Response res)
    {
        res.setContext("<H1>One....</H1> <br/>");
        return true;
    }
}

class TwoMiddleware : IMiddleware
{
    override string name()
    {
        return TwoMiddleware.stringof;
    }

    override bool onProcess(Request req, Response res)
    {
        res.setContext("<H1>Two....</H1> <br/>");
        return true;
    }
}


class BeforeMiddleware : IMiddleware
{
    override string name()
    {
        return BeforeMiddleware.stringof;
    }
    override bool onProcess(Request req, Response res)
    {
        res.setContext("<H1>BeforeMiddleware....</H1> <br/>");
        return true;
    }
}

class AfterMiddleware : IMiddleware
{
    override string name()
    {
        return AfterMiddleware.stringof;
    }
    override bool onProcess(Request req, Response res)
    {
        res.setContext("<H1>AfterMiddleware....</H1> <br/>");
        return true;
    }
}
