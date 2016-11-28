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
 
module hunt.router.config;

import std.string;
import std.regex;
import std.stdio;
import std.array;
import std.uni;
import std.conv;
import std.experimental.logger;

import hunt.router.configbase;


class RouterConfig : ConfigLine
{
     /*
     * @Param filePath - path of file
     * @Param prefix - prefix of module's full path, use "application.controllers" for default
     */
    this(string filePath, string prefix = "app.controller.")
    {
        super(filePath, prefix);
    }

    override RouterContext[] doParse()
    {
        RouterContext[] routerContext;
        File file = File(filePath, "r");
        string domain,path, filedir;
        scope(exit)
        {
            file.close();
        }
        while(!file.eof())
        {
            string line = file.readln();
            line = line.strip;
            if (line.length > 0 && line[0] != '#')
            {
                RouterContext tmpRoute;
                tmpRoute.routerType = RouterType.DOMAIN_DIR;
                tmpRoute.host = domain;
                tmpRoute.dir = path;
                auto len = line.length -1;
                version(route_simple_mode)
                {
                    //{bbs.putao.com}
                    if(line[0] == '{' && line[len] == '}')
                    {
                        domain = line[1..len];
                        continue;
                    }
                    //[/bbs]
                    else if(line[0] == '[' && line[len] == ']')
                    {
                        path = line[1..len];
                        continue;
                    }
                    else
                    {
                        string[] tmpSplites = spliteBySpace(line);
                        if(tmpSplites.length == 0) continue;
                        if (tmpSplites[0] == "*")
                            tmpRoute.method = fullMethod;
                        else
                            tmpRoute.method = toUpper(tmpSplites[0]);
                        tmpRoute.path = tmpSplites[1];
                        tmpRoute.hander = parseToFullController(tmpSplites[2]);
                        routerContext ~= tmpRoute;
                    }
                }
                else
                {
                    //[domain=bbs.putao.com@bbsdir]
                    //[path=bbs@bbsdir]
                    if(line[0] == '[' && line[len] == ']')
                    {
                        string[] _splitconfig = line[1..len].split('=');
                        if(_splitconfig.length != 2)
                        {
                            throw new Exception("config is error:" ~line);
                        }
                        if("domain" == _splitconfig[0].strip.toLower)
                        {
                            auto _index = _splitconfig[1].indexOf('@');
                            if(_index != -1)
                            {
                                domain = _splitconfig[1][0 .. _index].strip.toLower;
                                filedir = _splitconfig[1][_index+1 .. $].strip.toLower;
                            }
                            else
                            {
                                 domain = _splitconfig[1].strip.toLower;
                                 filedir = "";
                            }
                            path = "";

                        }
                        else if("path" == _splitconfig[0].strip.toLower)
                        {
                            auto _index = _splitconfig[1].indexOf('@');
                            if(_index != -1)
                            {
                                path = _splitconfig[1][0 .. _index].strip.toLower;
                                filedir = _splitconfig[1][_index+1 .. $].strip.toLower;
                            }
                            else
                            {
                                 path = _splitconfig[1].strip.toLower;
                                 filedir = "";
                            }
                            domain = "";
                        }
                        else
                        {
                            throw new Exception("not support config :" ~line);
                        }
                        continue;
                    }
                    else
                    {
                        string[] tmpSplites = spliteBySpace(line);
                        if(tmpSplites.length == 0) continue;
                        if (tmpSplites[0] == "*")
                            tmpRoute.method = fullMethod;
                        else
                            tmpRoute.method = toUpper(tmpSplites[0]);
                        tmpRoute.path = tmpSplites[1];
                        tmpRoute.hander = parseToFullController(tmpSplites[2], filedir);
                        routerContext ~= tmpRoute;
                    }
                }
            }
        }
        return routerContext;
        
    }
protected:
    string parseToFullController(string inBuff, string filedir)
    {
        string[] spritArr = split(inBuff, '.');
        assert(spritArr.length > 1, "whitout .");
        string output;
        spritArr[spritArr.length - 2] = spritArr[spritArr.length - 2] ~"."~ to!string(spritArr[spritArr.length - 2].asCapitalized) ~ controllerPrefix;
        output ~= prefix;
        if(filedir.length)
        {
            output ~= filedir;
            output ~= ".";
        }
        output ~= spritArr.join(".");
        trace("output: ", output);
        return output;
    }
}
