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
module hunt.router.configbase;

import std.file;
import std.string;
import std.regex;
import std.stdio;
import std.array;
import std.uni;
import std.conv;

/**
    Save the rule info.
*/
struct RouterContext
{
    string method;                              /// the method
    string path;                                /// the path.
    string hander;                              /// the handler  class.fun.
    RouterType routerType = RouterType.DEFAULT; /// the rule type.
    string host;                                /// the domain group.
    string dir;                                 /// the dir group.
}

/// the router rule type.
enum RouterType
{
    DOMAIN_DIR, /// with domain group and dir group.
    DOMAIN,     /// only with domain group
    DIR,        /// only with dir group
    DEFAULT     /// not any group
}

/**
    The router config base class.
*/
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

    RouterContext[] doParse();
    
    final @property filePath(){return _filePath;}

    final @property void filePath(string filePath)
    {
        this._filePath = filePath;
    }

    final @property prefix(){return _prefix;}
    final @property void prefix(string prefix)
    {
        this._prefix = prefix;
    }   

private:
    string _prefix;
    string _filePath; //文件路径
}


abstract class ConfigLine : RouterConfigBase
{
    this(string filePath, string prefix = "application.controllers.")
    {
        super(filePath,prefix);
    }
    
    final @property controllerPrefix(){return _controllerPrefix;}
    final @property controllerPrefix(string controllerPrefix)
    {
        _controllerPrefix = controllerPrefix;
    }
private:
    string _controllerPrefix = "Controller";
}

enum fullMethod = "OPTIONS,GET,HEAD,POST,PUT,DELETE,TRACE,CONNECT";

string[] spliteBySpace(string inBuff)
{
    auto r = regex(r"\S+");

    auto getSpliteItems = matchAll(inBuff, r);
    if(!getSpliteItems) return null;
    string[] output;
    foreach (s; getSpliteItems)
        output ~= cast(string) s.hit;
    return output;
}
