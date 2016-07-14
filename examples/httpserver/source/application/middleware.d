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


class WidgetFactory : IWidgetFactory
{
    override Widget[] getWidgets()
    {
        Widget[] _list;
        _list ~= new OneWidget();
        _list ~= new TwoWidget();
       return _list;
    }
}

class OneWidget : Widget
{
    override bool handle(Request req, Response res)
    {
        res.setContext("<H1>One....</H1> <br/>");
        return true;
    }
}

class TwoWidget : Widget
{
    override bool handle(Request req, Response res)
    {
        res.setContext("<H1>Two....</H1> <br/>");
        return true;
    }
}


class BeforeWidget : Widget
{
    override bool handle(Request req, Response res)
    {
        res.setContext("<H1>BeforeWidget....</H1> <br/>");
        return true;
    }
}

class AfterWidget : Widget
{
    override bool handle(Request req, Response res)
    {
        res.setContext("<H1>AfterWidget....</H1> <br/>");
        return true;
    }
}
