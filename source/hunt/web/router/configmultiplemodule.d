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
module hunt.web.router.configmultiplemodule;

import std.file;
import std.string;
import std.regex;
import std.stdio;
import std.array;
import std.uni;
import std.conv;

import hunt.web.router.configbase;
import hunt.config.ini;

final class ConfigMultipleModule : ConfigLine
{
    /***********************************
     *
     *
     *
     *
     **********************************/
    this(string filePath, string routerGroupPath, string prefix = "application.")
    {
	assert(exists(routerGroupPath), "Without file!");
	this._routerGroupPath = routerGroupPath;
        super(filePath, prefix);
    }

public:
    override RouterContext[] doParse()
    {
        RouterContext[] routerContext;
        
        File file = File(filePath, "r");

        while(!file.eof())
        {
            string line = file.readln();
            if (line != string.init && (line.indexOf('#') < 0))
            {
                string[] tmpSplites = spliteBySpace(line);
                if(tmpSplites.length == 0) continue;
                RouterContext tmpRoute;
                if (tmpSplites[0] == "*")
                    tmpRoute.method = fullMethod;
                else
                    tmpRoute.method = toUpper(tmpSplites[0]);
                tmpRoute.path = tmpSplites[1];
                Ini ini = new Ini(_routerGroupPath);
                parseToFullController(tmpSplites[2], ini, tmpRoute);
                if (tmpSplites.length == 4)
                    parseMiddleware(tmpSplites[3], tmpRoute.middleWareBefore,
                        tmpRoute.middleWareAfter);
                routerContext ~= tmpRoute;
            }
        }
        return routerContext;
    }
protected:
    void parseToFullController(string inBuff,Ini ini, ref RouterContext outRouterContext)
    {
	/// admin/user.admin.show
        string[] spritArr = split(inBuff, '/');
	//size_t spliterPos = inBuff.lastIndexOf("/");
	//assert(spliterPos != -1, "Without /");
        assert(spritArr.length == 2, "Style of group router error! Usage: admin/aa.bb.cc");
	///get groupName
	string groupType = ini.value("RouterGroup",spritArr[0]~".type");
	string groupItemValue = ini.value("RouterGroup", spritArr[0]~".value");
	if(groupType == "domain")
	{
	    outRouterContext.routerType = RouterType.DOMAIN;
	    outRouterContext.host = groupItemValue;
	}
	else if(groupType == "dir")
	{
	    outRouterContext.routerType = RouterType.DIR;
	    outRouterContext.dir = groupItemValue;
	}
	else
	{
	    outRouterContext.routerType = RouterType.DOMAIN;
	    outRouterContext.host = groupItemValue;
	}
        string output;
	string[] spritClass = split(spritArr[1], '.');
	spritClass[0] = spritClass[0]~"."~_controllerPathName;
        spritClass[spritClass.length - 2] = spritArr[0] ~ "." ~ spritClass[spritClass.length - 2] ~"."~ to!string(spritClass[spritClass.length - 2].asCapitalized) ~ controllerPrefix;
        output ~= prefix;
        output ~= spritClass.join(".");
	outRouterContext.hander = output;
	return;
    }
    
private:
    string _controllerPathName = "controller";
    string _routerGroupPath;
}
