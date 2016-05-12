module hunt.router.middleware;

import std.functional;

interface IMiddleWare(REQ, RES)
{
    alias Context = ContextImpl!(REQ, RES);
    void handle(Context ctx, REQ req, RES res);
}

abstract shared class IPipelineFactory(REQ, RES)
{
    alias Pipeline = PipelineImpl!(REQ, RES);
    Pipeline newPipeline();
}

final class PipelineImpl(REQ, RES)
{
    alias MiddleWare = IMiddleWare!(REQ, RES);
    alias Context = ContextImpl!(REQ, RES);
    alias HandleDelegate = void delegate(REQ, RES);
    alias Pipeline = PipelineImpl!(REQ, RES);

    this()
    {
        _first = new Context();
        _last = _first;
    }

    ~this()
    {
        _first.destroy;
        _last = null;
    }

    void addHandler(MiddleWare hander)
    in
    {
        assert(hander);
    }
    body
    {
        Context cxt = new Context(hander);
        _last._next = cxt;
        _last = cxt;
    }

    void addHandler(HandleDelegate handler)
    in
    {
        assert(handler);
    }
    body
    {
        Context cxt = new Context(new DelegateMiddleWare!(REQ,RES)(handler));
        _last._next = cxt;
        _last = cxt;
    }

    void append(Pipeline pipeline)
    {
        if (pipeline is null)
            return;
        if (pipeline.empty())
            return;
        Context frist = pipeline._first._next;
        while (frist !is null)
        {
            _last._next = frist;
            _last = frist;
            frist = frist._next;
        }
    }

    void handleActive(REQ req, RES res)
    {
        _first.next(forward!(req, res));
    }

    @property bool empty()
    {
        if (_first == _last)
            return true;
        else
            return false;
    }

    @property matchData()
    {
        return _matchData;
    }

    void addMatch(string key, string value)
    {
        _matchData[key] = value;
    }

private:
    Context _first = null;
    Context _last = null;
    string[string] _matchData;
}


final class ContextImpl(REQ, RES)
{
    alias MiddleWare = IMiddleWare!(REQ, RES);
    alias Context = ContextImpl!(REQ, RES);

    this()
    {
    }

    this(MiddleWare handler)
    {
        _middleWare = handler;
    }

    ~this()
    {
        _next = null;
        _middleWare = null;
    }

    void next(REQ req, RES res)
    {
        if (_next)
            _next.handle(forward!(req, res));
    }

private:
    void handle(REQ req, RES res)
    {
        if (_middleWare)
            _middleWare.handle(this, req, res);
    }

    MiddleWare _middleWare = null;
    Context _next = null;
}

private:
final class DelegateMiddleWare(REQ, RES) : IMiddleWare!(REQ, RES)
{
    alias HandleDelegate = void delegate(REQ, RES);

    this(HandleDelegate handle)
    {
        _handler = handle;
    }

    override void handle(Context ctx, REQ req, RES res)
    {
        _handler(req, res);
        ctx.next(forward!(req, res));
    }

private:
    HandleDelegate _handler;
}


unittest
{
    import std.functional;
    import std.stdio;

    class Test
    {
        int gtest  = 0;
    }


    class TestMiddleWare : IMiddleWare!(Test,int)
    {
        override void handle(Context ctx, Test a, int b)
        {
            a.gtest += 1;
            writeln("IMiddleWare handle : a.gtest : ",a.gtest);
            ctx.next(a,b);
        }
    }

    void testFun(Test a, int b)
    {
        ++ a.gtest;
    }

    alias Pipeline = PipelineImpl!(Test,int);

    Pipeline pip = new Pipeline();
    pip.addHandler(new TestMiddleWare());
    pip.addHandler(new TestMiddleWare());
    pip.addHandler(new TestMiddleWare());
    pip.addHandler(toDelegate(&testFun));
    pip.addHandler(new TestMiddleWare());
    pip.addHandler(new TestMiddleWare());

    Test t = new Test();
    pip.handleActive(t,0);

    writeln("t.gtest is :", t.gtest);
    assert(t.gtest == 6);

    class TestMiddleWare2 : IMiddleWare!(Test,int)
    {
        override void handle(Context ctx, Test a, int b)
        {
            a.gtest -= 1;
            writeln("IMiddleWare2 handle : a.gtest : ",a.gtest);
            ctx.next(a,b);
        }
    }

    void testFun2(Test a, int b)
    {
        a.gtest -= 1;
    }

    Pipeline pip2 = new Pipeline();
    pip2.addHandler(new TestMiddleWare2());
    pip2.addHandler(new TestMiddleWare2());
    pip2.addHandler(new TestMiddleWare2());
    pip2.addHandler(toDelegate(&testFun2));
    pip2.addHandler(new TestMiddleWare2());
    pip2.addHandler(new TestMiddleWare2());

    pip.append(pip2);

    pip.handleActive(t,0);

    assert(t.gtest == 6);
}