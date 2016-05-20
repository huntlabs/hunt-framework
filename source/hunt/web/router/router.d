module hunt.web.router.router;

import std.regex;
import std.stdio;
import std.string;
import std.experimental.logger;

import hunt.web.router.middleware;
import hunt.web.router.utils;


final class Router(REQ, RES)
{
    alias HandleDelegate = void delegate(REQ, RES);
    alias Pipeline = PipelineImpl!(REQ, RES);
    alias PipelineFactory = IPipelineFactory!(REQ, RES);
    alias RouterElement = PathElement!(REQ, RES);
    alias RouterMap = ElementMap!(REQ, RES);

    void setGlobalBeforePipelineFactory(shared PipelineFactory before)
    {
        _gbefore = before;
    }

    void setGlobalAfterPipelineFactory(shared PipelineFactory after)
    {
        _gafter = after;
    }

    RouterElement addRouter(string method, string path, HandleDelegate handle,
        shared PipelineFactory before = null, shared PipelineFactory after = null)
    {
        if (condigDone)
            return null;
        RouterMap map = _map.get(method, null);
        if (!map)
        {
            map = new RouterMap(this);
            _map[method] = map;
        }
        return map.add(path, handle, before, after);
    }
 
    ///group router is domain, groupName fill domain
    RouterElement addGroupRouter(string groupName, string method, string path, HandleDelegate handle,
	    shared PipelineFactory before = null, shared PipelineFactory after = null)
    {
        if (condigDone)
            return null;
	_useGroupRouter = true;
	if(groupName !in _groupMap)
	    _groupMap[groupName][method] = new RouterMap(this);
	if(groupName in _groupMap && !_groupMap[groupName].get(method,null))
	    _groupMap[groupName][method] = new RouterMap(this);
	trace("groupName: ", groupName, " method: ", method, " path: ", path);
	return _groupMap[groupName][method].add(path, handle, before, after);
    }

    Pipeline groupMatch(string host, string method, string path)
    {
	trace("function: ", __FUNCTION__);
	if(!condigDone)
	    return null;
	trace("host: ",host, " method: ", method, " path: ", path);
	if(host in _groupMap && _groupMap[host].get(method,null))
	    return _groupMap[host][method].match(path);
	if(host !in _groupMap)
	{
	    string groupName;
	    string usingPath;
	    groupName = getFirstPath(path, usingPath);
	    trace("groupName: ", groupName, " usingPath: ", usingPath);
	    
	    trace("usingPath: ", usingPath);
	    if(groupName in _groupMap && _groupMap[groupName].get(method,null))
		return _groupMap[groupName][method].match(usingPath);
	}
	return null;
    }
    Pipeline match(string method, string path)
    {
        Pipeline pipe = null;
        if (!condigDone)
            return pipe;
        RouterMap map = _map.get(method, null);
        if (!map)
            return pipe;
        pipe = map.match(path);
        return pipe;
    }

    Pipeline getGlobalBrforeMiddleware()
    {
        if (_gbefore)
            return _gbefore.newPipeline();
        else
            return null;
    }

    Pipeline getGlobalAfterMiddleware()
    {
        if (_gafter)
            return _gafter.newPipeline();
        else
            return null;
    }

    @property bool condigDone()
    {
        return _configDone;
    }
    
    @property bool usingGroupRouter()
    {
	return _useGroupRouter;
    }

    void done()
    {
        _configDone = true;
    }

private:
    shared PipelineFactory _gbefore = null;
    shared PipelineFactory _gafter = null;
    RouterMap[string] _map;
    RouterMap[string][string]  _groupMap;
    bool _configDone = false;
    bool _useGroupRouter = false;
}

class PathElement(REQ, RES)
{
    alias HandleDelegate = void delegate(REQ, RES);
    alias Pipeline = PipelineImpl!(REQ, RES);
    alias PipelineFactory = IPipelineFactory!(REQ, RES);

    this(string path)
    {
        _path = path;
    }

    PathElement!(REQ, RES) macth(string path, Pipeline pipe)
    {
        return this;
    }

    final @property path() const
    {
        return _path;
    }

    final @property handler() const
    {
        return _handler;
    }

    final @property handler(HandleDelegate handle)
    {
        _handler = handle;
    }

    final Pipeline getBeforeMiddleware()
    {
        if (_before)
            return _before.newPipeline();
        else
            return null;
    }

    final Pipeline getAfterMiddleware()
    {
        if (_after)
            return _after.newPipeline();
        else
            return null;
    }

    final void setBeforePipelineFactory(shared PipelineFactory before)
    {
        _before = before;
    }

    final void setAfterPipelineFactory(shared PipelineFactory after)
    {
        _after = after;
    }

private:
    string _path;
    HandleDelegate _handler = null;
    shared PipelineFactory _before = null;
    shared PipelineFactory _after = null;
}

private:

final class RegexElement(REQ, RES) : PathElement!(REQ, RES)
{
    this(string path)
    {
        super(path);
    }

    override PathElement!(REQ, RES) macth(string path, Pipeline pipe)
    {
        //writeln("the path is : ", path, "  \t\t regex is : ", _reg);
        auto rg = regex(_reg, "s");
        auto mt = matchFirst(path, rg);
        if (!mt)
        {
            return null;
        }
        foreach (attr; rg.namedCaptures)
        {
            pipe.addMatch(attr, mt[attr]);
        }
        return this;
    }

private:
    bool setRegex(string reg)
    {
        if (reg.length == 0)
            return false;
        _reg = buildRegex(reg);
        if (_reg.length == 0)
            return false;
        return true;
    }

    string _reg;
}

final class RegexMap(REQ, RES)
{
    alias RElement = RegexElement!(REQ, RES);
    alias PElement = PathElement!(REQ, RES);
    alias RElementMap = RegexMap!(REQ, RES);
    alias Pipeline = PipelineImpl!(REQ, RES);

    this(string path)
    {
        _path = path;
    }

    PElement add(RElement ele, string preg)
    {
        string rege;
        string str = getFirstPath(preg, rege);
        //writeln("RegexMap add : path = ", ele.path, " \n\tpreg = ", preg, "\n\t str = ", str,
        //       "\n\t rege = ", rege, "\n");
        if (str.length == 0)
        {
            ele.destroy;
            return null;
        }
        if (isHaveRegex(str))
        {
            //  writeln("set regex is  : ", preg);
            if (!ele.setRegex(preg))
                return null;

            bool isHas = false;
            for (int i = 0; i < _list.length; ++i) //添加的时候去重
            {
                if (_list[i].path == ele.path)
                {
                    isHas = true;
                    auto tele = _list[i];
                    _list[i] = ele;
                    tele.destroy;
                }
            }
            if (!isHas)
            {
                _list ~= ele;
            }
            return ele;
        }
        else
        {
            RElementMap map = _map.get(str, null);
            if (!map)
            {
                map = new RElementMap(str);
                _map[str] = map;
            }
            return map.add(ele, rege);
        }
    }

    PElement match(string path, Pipeline pipe)
    {
        // writeln(" \t\tREGEX macth path:  ", path);
        if (path.length == 0)
            return null;
        string lpath;
        string frist = getFirstPath(path, lpath);
        if (frist.length == 0)
            return null;
        RElementMap map = _map.get(frist, null);
        if (map)
        {
            return map.match(lpath, pipe);
        }
        else
        {
            foreach (ele; _list)
            {
                auto element = ele.macth(path, pipe);
                if (element)
                {
                    return element;
                }
            }
        }
        return null;
    }

private:
    RElementMap[string] _map;
    RElement[] _list;
    string _path;
}

final class ElementMap(REQ, RES)
{
    alias RElement = RegexElement!(REQ, RES);
    alias PElement = PathElement!(REQ, RES);
    alias RElementMap = RegexMap!(REQ, RES);
    alias Pipeline = PipelineImpl!(REQ, RES);
    alias Route = Router!(REQ, RES);
    alias HandleDelegate = void delegate(REQ, RES);
    alias PipelineFactory = IPipelineFactory!(REQ, RES);

    this(Route router)
    {
        _router = router;
        _regexMap = new RElementMap("/");
    }

    PElement add(string path, HandleDelegate handle, shared PipelineFactory before,
        shared PipelineFactory after)
    {
        if (isHaveRegex(path))
        {
            auto ele = new RElement(path);
            ele.setAfterPipelineFactory(after);
            ele.setBeforePipelineFactory(before);
            ele.handler = handle;
            return _regexMap.add(ele, path);
        }
        else
        {
	    trace("add function: ", path, " handle: ", handle.ptr);
            auto ele = new PElement(path);
            ele.setAfterPipelineFactory(after);
            ele.setBeforePipelineFactory(before);
            ele.handler = handle;
            _pathMap[path] = ele;
            return ele;
        }
    }

    Pipeline match(string path)
    {
        Pipeline pipe = new Pipeline();

        PElement element = _pathMap.get(path, null);
	writeln("element: ", element);

        if (!element)
        {
            element = _regexMap.match(path, pipe);
        }

        if (element)
        {
            pipe.append(_router.getGlobalBrforeMiddleware());
            pipe.append(element.getBeforeMiddleware());
            pipe.addHandler(element.handler);
            pipe.append(element.getAfterMiddleware());
            pipe.append(_router.getGlobalAfterMiddleware());

        }
        else
        {
            pipe.destroy;
            pipe = null;
        }
        return pipe;
    }

private:
    Route _router;
    PElement[string] _pathMap;
    RElementMap _regexMap;
}

unittest
{
    import std.functional;
    import std.stdio;

    class Test
    {
        int gtest = 0;
    }

    alias Route = Router!(Test, int);
    class TestMiddleWare : IMiddleWare!(Test, int)
    {
        override void handle(Context ctx, Test a, int b)
        {
            a.gtest += 1;
            writeln("\tIMiddleWare handle : a.gtest : ", a.gtest);
            ctx.next(a, b);
        }
    }

    void testFun(Test a, int b)
    {
        ++a.gtest;
    }

    shared class Factor : IPipelineFactory!(Test, int)
    {
        alias Pipeline = PipelineImpl!(Test, int);
        override Pipeline newPipeline()
        {
            auto pip = new Pipeline();
            pip.addHandler(new TestMiddleWare());
            pip.addHandler(new TestMiddleWare());
            return pip;
        }
    }

    Test a = new Test();

    Route router = new Route();

    router.setGlobalBeforePipelineFactory(new shared Factor());
    router.setGlobalAfterPipelineFactory(new shared Factor());

    auto ele = router.addRouter("get", "/file", toDelegate(&testFun),
        new shared Factor(), new shared Factor());
    assert(ele !is null);
    ele = router.addRouter("get",
        "/file/{:[0-9a-z]{1}}/{d2:[0-9a-z]{2}}/{imagename:\\w+\\.\\w+}",
        toDelegate(&testFun), new shared Factor(), new shared Factor());
    assert(ele !is null);
    ele = router.addRouter("post",
        "/file/{d1:[0-9a-z]{1}}/{d2:[0-9a-z]{2}}/{imagename:\\w+\\.\\w+}", toDelegate(&testFun));
    assert(ele !is null);
    router.done();

    auto pipe = router.match("post", "/file");
    assert(pipe is null);
    pipe = router.match("post", "/");
    assert(pipe is null);

    pipe = router.match("get", "/file");
    assert(pipe !is null);
    a.gtest = 0;
    pipe.handleActive(a, 0);
    assert(a.gtest == 9);

    pipe = router.match("post", "/file/2/34/ddd.jpg");
    assert(pipe !is null);
    assert(pipe.matchData.length == 3);
    a.gtest = 0;
    pipe.handleActive(a, 0);
    assert(a.gtest == 5);

    pipe = router.match("get", "/file/2/34/ddd.jpg");
    assert(pipe !is null);
    assert(pipe.matchData.length == 2);
    a.gtest = 0;
    pipe.handleActive(a, 0);
    assert(a.gtest == 9);

}
