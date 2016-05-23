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
module hunt.web.router.ConfigMultipleModule;

import std.file;
import std.string;
import std.regex;
import std.stdio;
import std.array;
import std.uni;
import std.conv;

import hunt.web.router.RouterConfigBase;
import hunt.config.ini;

class ConfigMultipleModule : RouterConfigBase
{
    import std.experimental.logger;
    this(string filePath, string routerGroupPath, string prefix = "application.controllers.")
    {
	assert(exists(routerGroupPath), "Without file!");
	this._routerGroupPath = routerGroupPath;
	prefix = "application.";
        super(filePath, prefix);
    }

public:
    override @property RouterContext[] doParse()
    {
        string fullMethod = "OPTIONS,GET,HEAD,POST,PUT,DELETE,TRACE,CONNECT";
        string[] outputLines;
        size_t fileSize = cast(size_t) getSize(cast(char[]) _filePath);
        assert(fileSize, "Empty file!");
        string readBuff;
        try
        {
            readBuff = cast(string) read(cast(char[]) _filePath, fileSize);
        }
        catch (Exception ex)
        {
            assert("Read router config file error!");
            throw ex;
        }
        string[] lineBuffers = splitLines(readBuff);
        foreach (line; lineBuffers)
        {
            if (line != string.init && (line.indexOf('#') < 0))
            {
                string[] tmpSplites = spliteBySpace(line);
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
                _routerContext ~= tmpRoute;
            }
        }
        return _routerContext;
    }

    void setControllerPrefix(string controllerPrefix)
    {
        _controllerPrefix = controllerPrefix;
    }

    void setBeforeFlag(string beforeFlag)
    {
        _beforeFlag = beforeFlag;
    }

    void setAfterFlag(string afterFlag)
    {
        _afterFlag = afterFlag;
    }

private:
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
        spritClass[spritClass.length - 2] = spritClass[spritClass.length - 2] ~"."~ to!string(spritClass[spritClass.length - 2].asCapitalized) ~ _controllerPrefix;
        output ~= _prefix;
        output ~= spritClass.join(".");
	outRouterContext.hander = output;
	return;
    }

    string[] spliteBySpace(string inBuff)
    {
        auto r = regex(r"\S+");

        auto getSpliteItems = matchAll(inBuff, r);
        assert(getSpliteItems, "Could not splite by space!");
        string[] output;
        foreach (s; getSpliteItems)
            output ~= cast(string) s.hit;
        return output;
    }
    
    
    void parseMiddleware(string toParse, out string[] beforeMiddleware, out string[] afterMiddleware)
    {
        size_t beforePos, afterPos, semicolonPos;
        beforePos = toParse.indexOf(_beforeFlag);
        afterPos = toParse.indexOf(_afterFlag);
        semicolonPos = toParse.indexOf(";");
        assert(beforePos <= afterPos, "after position and before position worry");
        if (beforePos < 0)
            beforePos = toParse.length - 1;
        else
            beforePos += _beforeFlag.length;
        if (afterPos < 0)
            afterPos = toParse.length - 1;
        else
            afterPos += _afterFlag.length;
        if (semicolonPos < 0)
            semicolonPos = toParse.length - 1;
        if (beforePos < semicolonPos)
            beforeMiddleware = split(toParse[beforePos .. semicolonPos], ',');
        afterMiddleware = split(toParse[afterPos .. $], ',');
    }

private:
    string _controllerPrefix = "Controller";
    string _controllerPathName = "controller";
    string _beforeFlag = "before:";
    string _afterFlag = "after:";
    string _routerGroupPath;
}
