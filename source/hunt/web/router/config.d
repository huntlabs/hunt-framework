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
 
module hunt.web.router.config;

import std.string;
import std.regex;
import std.stdio;
import std.array;
import std.uni;
import std.conv;
import std.experimental.logger;

import hunt.routing.configbase;


class RouterConfig : ConfigLine
{
     /*
     * @Param filePath - path of file
     * @Param prefix - prefix of module's full path, use "application.controllers" for default
     */
    this(string filePath, string prefix = "application.controllers.")
    {
        super(filePath, prefix);
    }

    override RouterContext[] doParse()
    {
        RouterContext[] routerContext;
        File file = File(filePath, "r");
        string domain,path;
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
                if(line[0] == '{' && line[len] == '}')
                {
                    domain = line[1..len];
                    continue;
                }
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
                    
                    if (tmpSplites.length == 4)
                        parseMiddleware(tmpSplites[3], tmpRoute.middleWareBefore,
                            tmpRoute.middleWareAfter);
                    routerContext ~= tmpRoute;
                }
            }
        }
        return routerContext;
        
    }
protected:
    string parseToFullController(string inBuff)
    {
        string[] spritArr = split(inBuff, '.');
        assert(spritArr.length > 1, "whitout .");
        string output;
        spritArr[spritArr.length - 2] = spritArr[spritArr.length - 2] ~"."~ to!string(spritArr[spritArr.length - 2].asCapitalized) ~ controllerPrefix;
        output ~= prefix;
        output ~= spritArr.join(".");
        trace("output: ", output);
        return output;
    }
}