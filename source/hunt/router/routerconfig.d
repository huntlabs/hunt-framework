module hunt.router.routerconfig;

import std.file;
import std.string;
import std.regex;
import std.stdio;
import std.array;
import std.uni;
import std.conv;

struct RouterContext
{
    string method;
    string path;
    string hander;
    string[] middleWareBefore;
    string[] middleWareAfter;
}

class RouterConfig
{
    this(string filePath, string prefix)
    in
    {
        assert(exists(filePath), "Error file path!");
    }
    body
    {
        _filePath = filePath;
        _prefix = prefix;
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

    void set_prefix(string prefix)
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
    this(string filePath, string prefix = string.init)
    {
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
                tmpRoute.hander = parseToFullControll(tmpSplites[2]);
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
    string parseToFullControll(string inBuff)
    {
        string[] spritArr = split(inBuff, '/');
        assert(spritArr.length > 1, "whitout /");
        string output;
        if (_prefix)
        {
            assert(spritArr.length == 4, "Wrong controller config!");
            output ~= spritArr[0] ~ "." ~ spritArr[1] ~ "." ~ to!string(spritArr[2].asCapitalized) ~ _controllerPrefix ~ "." ~ spritArr[
                3];
        }
        else
        {
            assert(spritArr.length == 3, "Wrong controller config!");
            output ~= "application" ~ "." ~ spritArr[0] ~ "." ~ to!string(spritArr[1].asCapitalized) ~ _controllerPrefix ~ "." ~ spritArr[
                2];
        }

        return output;
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
        int beforePos, afterPos, semicolonPos;
        beforePos = toParse.indexOf(_beforeFlag);
        afterPos = toParse.indexOf(_afterFlag);
        semicolonPos = toParse.indexOf(";");
        assert(beforePos <= afterPos, "after position and before position worry");
        //assert(beforePos 
        writeln("toParse: ", toParse, " beforePos: ", beforePos);
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
        writeln("beforeMiddleware: ", beforeMiddleware, " afterMiddleware: ", afterMiddleware);
    }

private:
    string _controllerPrefix = "Controller";
    string _beforeFlag = "before:";
    string _afterFlag = "after:";
}

unittest
{
    ConfigParse new_parse = new ConfigParse("router.conf");
    //new_parse.setFilePath("router.conf");
    RouterContext[] test_router_context = new_parse.doParse();
    foreach (item; test_router_context)
    {
        writeln("method: ", item.method, " path: ", item.path, " hander: ",
            item.hander, " middleWareAfter: ", item.middleWareAfter,
            " middleWareBefore: ", item.middleWareBefore);
    }
}
