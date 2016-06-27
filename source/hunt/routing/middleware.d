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
module hunt.routing.middleware;

import std.functional;
public import std.variant;

/**
    The MiddleWare interface.
*/
interface IMiddleWare(ARGS...)
{
	alias Context = ContextImpl!(ARGS);
	/// the handle will be call in the pipeline handler.
	void handle(Context ctx, ARGS args);
}

/**
    This class is create a Pipeline.
*/
abstract shared class IPipelineFactory(ARGS...)
{
	alias Pipeline = PipelineImpl!(ARGS);
	/// return a Pipeline.
    Pipeline newPipeline();
}

/**
    The pipeline like a list. it call the MiddleWare form frist to last.
*/
final class PipelineImpl(ARGS...)
{
	alias MiddleWare = IMiddleWare!(ARGS);
	alias Context = ContextImpl!(ARGS);
	alias HandleDelegate = void delegate(ARGS);
	alias Pipeline = PipelineImpl!(ARGS);
	alias ContextDelegate = void delegate(Context,ARGS);

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

    /// add a MiddleWare
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

    /// add a delegate and it auto create a MiddleWare.
    void addHandler(HandleDelegate handler)
    in
    {
        assert(handler);
    }
    body
    {
		Context cxt = new Context(new DelegateMiddleWare!(ARGS)(handler));
        _last._next = cxt;
        _last = cxt;
    }

	/// add a delegate and it auto create a MiddleWare.
	void addHandler(ContextDelegate handler)
	in
	{
		assert(handler);
	}
	body
	{
		Context cxt = new Context(new ContextMiddleWare!(ARGS)(handler));
		_last._next = cxt;
		_last = cxt;
	}
	
	/// append a pipeline to the last.
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

    /// start handle the MiddleWare, from frist to last.
	void handleActive(ARGS args)
	{
		_first.next(forward!(args));
	}

    /// Does this pipeline have any MiddleWare.
    @property bool empty()
    {
        if (_first == _last)
            return true;
        else
            return false;
    }

    /// get the match data. data is in path.
    @property matchData()
    {
        return _matchData;
    }

    /// add a match data.
    void addMatch(string key, string value)
    {
        _matchData[key] = value;
    }

    /// swap the match data.
    void swapMatchData(ref string[string] to)
    {
        import std.algorithm.mutation : swap;
        swap(to,_matchData);
    }
private:
    Context _first = null;
    Context _last = null;
    string[string] _matchData;
}

/**
    The Context Class.
*/
final class ContextImpl(ARGS...)
{
	alias MiddleWare = IMiddleWare!(ARGS);
	alias Context = ContextImpl!(ARGS);

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

    /**
        call the next handle.
    */
	void next(ARGS args)
	{
        if (_next)
			_next.handle(this,forward!(args));
	}

	Variant data;

private:
	void handle(Context last,ARGS args)
	{
		import std.algorithm.mutation;
		swap(last.data,this.data);
        if (_middleWare)
			_middleWare.handle(this, args);
		//import collie.utils.memory;
		//gcFree(last);
	}
	
	MiddleWare _middleWare = null;
    Context _next = null;
}

final shared class AutoMiddleWarePipelineFactory(ARGS...): IPipelineFactory!(ARGS)
{
    import std.experimental.logger;

	alias MiddleWare = IMiddleWare!(ARGS);
	this(string[] middle)
    {
        this(cast(shared string[]) middle);
    }

    this(shared string[] middle)
    {
        _middleList = middle;
    }

    override Pipeline newPipeline()
    {
        if (_middleList.length == 0)
            return null;
        Pipeline pipe = new Pipeline();
        foreach (ref str; _middleList)
        {
            auto obj = Object.factory(str);
            if (!obj)
            {
                error("Object.factory erro!, the obj Name is : ", str);
                continue;
            }
            auto a = cast(MiddleWare) obj;
            if (!a)
            {
                error("cast(MiddleWare)obj; erro!");
                continue;
            }
            pipe.addHandler(a);
        }
        return pipe;
    }

private:
    string[] _middleList;
}

private:
final class DelegateMiddleWare(ARGS...) : IMiddleWare!(ARGS)
{
	alias HandleDelegate = void delegate(ARGS);
	
    this(HandleDelegate handle)
    {
        _handler = handle;
    }

	override void handle(Context ctx, ARGS args)
	{
		_handler(args);
	//	ctx.next(forward!(args));
    }

private:
    HandleDelegate _handler;
}


final class ContextMiddleWare(ARGS...) : IMiddleWare!(ARGS)
{
	alias ContextDelegate = void delegate(Context,ARGS);
	
	this(ContextDelegate handle)
	{
		_handler = handle;
	}
	
	override void handle(Context ctx, ARGS args)
	{
		_handler(ctx,args);
	}
	
private:
	ContextDelegate _handler;
}

version (unittest)
{
    import std.stdio;

    class Test
    {
        int gtest = 0;
    }

    class TestMiddleWare : IMiddleWare!(Test, int)
    {
        override void handle(Context ctx, Test a, int b)
        {
            a.gtest += 1;
            writeln("IMiddleWare handle : a.gtest : ", a.gtest);
            ctx.next(a, b);
        }
    }

    class TestMiddleWare2 : IMiddleWare!(Test, int)
    {
        override void handle(Context ctx, Test a, int b)
        {
            a.gtest -= 1;
            writeln("IMiddleWare2 handle : a.gtest : ", a.gtest);
            ctx.next(a, b);
        }
    }
}

unittest
{
    import std.functional;
    import std.stdio;

    void testFun(Test a, int b)
    {
        ++a.gtest;
    }

    void testFun2(Test a, int b)
    {
        a.gtest -= 1;
    }

    alias Pipeline = PipelineImpl!(Test, int);

    Pipeline pip = new Pipeline();
    pip.addHandler(new TestMiddleWare());
    pip.addHandler(new TestMiddleWare());
    pip.addHandler(new TestMiddleWare());
    pip.addHandler(toDelegate(&testFun));
    pip.addHandler(new TestMiddleWare());
    pip.addHandler(new TestMiddleWare());

    Test t = new Test();
    pip.handleActive(t, 0);

    writeln("t.gtest is :", t.gtest);
    assert(t.gtest == 6);

    Pipeline pip2 = new Pipeline();
    pip2.addHandler(new TestMiddleWare2());
    pip2.addHandler(new TestMiddleWare2());
    pip2.addHandler(new TestMiddleWare2());
    pip2.addHandler(toDelegate(&testFun2));
    pip2.addHandler(new TestMiddleWare2());
    pip2.addHandler(new TestMiddleWare2());

    pip.append(pip2);

    pip.handleActive(t, 0);

    assert(t.gtest == 6);

    string[] list = [
        "hunt.routing.middleware.TestMiddleWare",
        "hunt.routing.middleware.TestMiddleWare",
        "hunt.routing.middleware.TestMiddleWare", "hunt.routing.middleware.TestMiddleWare"
    ];
    auto pipefactor = new shared AutoMiddleWarePipelineFactory!(Test, int)(list);
    auto pipe3 = pipefactor.newPipeline();
    t.gtest = 0;
    pipe3.handleActive(t, 0);
    writeln("t.gtest is :", t.gtest);
    assert(t.gtest == 4);
}
