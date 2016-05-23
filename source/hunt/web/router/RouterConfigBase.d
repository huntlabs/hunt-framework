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
module hunt.web.router.RouterConfigBase;

import std.file;
import std.string;
import std.regex;
import std.stdio;
import std.array;
import std.uni;
import std.conv;

import hunt.config.ini;

struct RouterContext
{
    string method;
    string path;
    string hander;
    RouterType routerType = RouterType.DEFAULT;
    string host;
    string dir;
    string[] middleWareBefore;
    string[] middleWareAfter;
}
enum RouterType
{
    DOMAIN_DIR,
    DOMAIN,
    DIR,
    DEFAULT,
}

abstract class RouterConfigBase
{
    this(string filePath, string prefix = "application.controllers.")
    in
    {
        assert(exists(filePath), filePath~" Error file path!");
    }
    body
    {
        _filePath = filePath;
        _prefix = prefix;
        if(_prefix.length > 0 && _prefix[_prefix.length - 1] != '.'){
            _prefix ~= ".";
        }
    }

    ~this()
    {

    }

    RouterContext[] doParse()
    {
        return this._routerContext;
    }

    void setFilePath(string filePath)
    {
        this._filePath = filePath;
    }

    void setPrefix(string prefix)
    {
        this._prefix = prefix;
    }

protected:
    RouterContext[] _routerContext;
    string _prefix;
    string _filePath; //文件路径
}
