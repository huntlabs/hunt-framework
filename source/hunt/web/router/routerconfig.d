module hunt.web.router.routerconfig;

import std.file;
import std.string;
import std.regex;
import std.stdio;
import std.array;
import std.uni;
import std.conv;

import hunt.web.router.ini;

struct RouterContext
{
    string method;
    string path;
    string hander;
    RouterType routerType;
    string host;
    string dir;
    string[] middleWareBefore;
    string[] middleWareAfter;
}
enum RouterType
{
    DOMAIN,
    DIR,
    DEFAULT,
}

abstract class RouterConfig
{
    this(string filePath, string prefix = "application.controllers.")
    in
    {
        assert(exists(filePath), "Error file path!");
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

class ConfigParse : RouterConfig
{
    import std.experimental.logger;
    this(string filePath, string prefix = "application.controllers.", string routerGroupPath=string.init)
    {
        super(filePath, prefix);
	if(routerGroupPath != string.init)
	{
	    assert(exists(routerGroupPath), "Without file!");
	    this._useRouterGroup = true;
	    this._routerGroupPath = routerGroupPath;
	}
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
            //assert("Read router config file error!);
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
		if(!_useRouterGroup)
		    tmpRoute.hander = parseToFullControllerWithDefault(tmpSplites[2]);
		else
		{
		    Ini ini = new Ini(_routerGroupPath);
		    parseToFullControllerWithGroup(tmpSplites[2], ini, tmpRoute);
		}
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
    string parseToFullControllerWithDefault(string inBuff)
    {
        string[] spritArr = split(inBuff, '/');
        assert(spritArr.length > 1, "whitout /");
        string output;
        spritArr[spritArr.length - 2] = to!string(spritArr[spritArr.length - 2].asCapitalized) ~ _controllerPrefix;
        output ~= _prefix;
        output ~= spritArr.join(".");
        return output;
    }

    void parseToFullControllerWithGroup(string inBuff,Ini ini, ref RouterContext outRouterContext)
    {
	/// admin/user.admin.show
        string[] spritArr = split(inBuff, '/');
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
        spritClass[spritClass.length - 2] = to!string(spritClass[spritClass.length - 2].asCapitalized) ~ _controllerPrefix;
        output ~= _prefix;
        output ~= spritClass.join(".");
	trace("++++++output: ", output);
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
        //assert(beforePos 
        trace("toParse: ", toParse, " beforePos: ", beforePos);
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
        trace("beforeMiddleware: ", beforeMiddleware, " afterMiddleware: ", afterMiddleware);
    }

private:
    string _controllerPrefix = "Controller";
    string _controllerPathName = "controller";
    string _beforeFlag = "before:";
    string _afterFlag = "after:";
    bool   _useRouterGroup=false;
    string _routerGroupPath;
}

void main()
{
    ConfigParse new_parse = new ConfigParse("router.conf", "routerGroup.ini");
    //new_parse.setFilePath("router.conf");
    RouterContext[] test_router_context = new_parse.doParse();
    foreach (item; test_router_context)
    {
        writeln("method: ", item.method, " path: ", item.path, " hander: ",
            item.hander, " middleWareAfter: ", item.middleWareAfter,
            " middleWareBefore: ", item.middleWareBefore);
    }
}
