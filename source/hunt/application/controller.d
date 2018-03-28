/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.application.controller;

import std.experimental.logger;

public import hunt.view;
public import hunt.http.response;
public import hunt.http.request;
public import hunt.routing;
public import hunt.application.middleware;

import huntlabs.cache;
import hunt.application.application;

import std.exception;
import std.traits;

enum Action;

struct Middleware
{
    string className;
}


abstract class Controller
{
    protected
    {
        Request request;
        ///called before all actions
        IMiddleware[] middlewares;
        View _view;
    }
    final @property session()
    {
        return request.getSession();
    }
    final @property response()
    {
        return request.createResponse();
    }
    /// called before action  return true is continue false is finish
    bool before(){return true;}

    /// called after action  return true is continue false is finish
    bool after(){return true;}

    ///add middleware
    ///return true is ok, the named middleware is already exist return false
    bool addMiddleware(IMiddleware m)
    {
        if(m is null) return false;
        foreach(tmp; this.middlewares)
        {
            if(tmp.name == m.name)
            {
                return false;
            }
        }

        this.middlewares ~= m;
        return true;
    }

    // get all middleware
    IMiddleware[] getMiddlewares()
    {
        return this.middlewares;
    }

    //view render
    @property View view()
    {
        if(_view is null)
        {
            _view = new View();
        }
        return _view;
    }

    @property UCache cache()
    {
		return Application.getInstance().getCache();
    }

	@property cacheManger()
	{
		return Application.getInstance().getCacheManger();
	}

    void render(string filename = null)()
    {
        this.response.html(this.view.render!filename());
    }
	alias show = render;

    void done()
    {
        this.response.done();
    }

    protected final bool doMiddleware()
    {
        trace("doMiddlware ..");

        foreach(m; middlewares)
        {
            tracef("do %s onProcess ..", m.name());

            auto response = m.onProcess(this.request, this.response);
            if(response is null)
            {
                continue;
            }

            tracef("Middleware %s is retrun done.", m.name);
            response.done();
            return false;
        }

        return true;
    }

	@property bool isAsync()
	{
		return true;
	}
}

mixin template MakeController(string moduleName = __MODULE__)
{
    mixin HuntDynamicCallFun!(typeof(this),moduleName);
}

mixin template HuntDynamicCallFun(T,string moduleName)
{
public:
    mixin(__createCallActionFun!(T,moduleName));
    shared static this()
    {
        mixin(__creteRouteMap!(T,moduleName));
    }
}

string  __createCallActionFun(T, string moduleName)()
{
    import std.traits;
    import std.format;

    string str = "bool callAction(string funName, Request req) {";
    str ~= "\n\tauto ptr = this; ptr.request = req;";
    str ~= "\n\tswitch(funName){";
    foreach(memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
        {
            foreach (t;__traits(getOverloads,T,memberName)) 
            {
                //alias pars = ParameterTypeTuple!(t);
                static if(/*ParameterTypeTuple!(t).length == 0 && */( hasUDA!(t, Action) || hasUDA!(t, Route)))
                {
                    str ~= "case \"";
                    str ~= memberName;
                    str ~= "\": {\n";
                    static if(hasUDA!(t, Action))
                    {
                        enum middlewares = getUDAs!(t, Middleware);
                        static if(middlewares.length)
                        {
                            foreach(i, middleware; middlewares)
                            {
                                str ~= format("ptr.addMiddleware(new %s);", middleware.className);
                            }
                        }

                        str ~= "if(!ptr.doMiddleware()){return false;}";

                        //before
                        str ~= q{
                            if(!ptr.before()){return false;}
                        };
                    }

                    //action
                    str ~= "ptr." ~ memberName ~ "();";

                    static if(hasUDA!(t, Action)){
                        //after
                        str ~= q{
                            if(!ptr.after()){return false;}
                        };
                    }
                    str ~= "}\n break;";
                }
            }
        }
    }

    str ~= "default : break;}";
    str ~= "return false;";
    str ~= "}";

    return str;
}

string  __creteRouteMap(T, string moduleName)()
{
    string str = "";

    //pragma(msg, "moduleName", moduleName);
    str ~= "\n\timport hunt.application.staticfile;\n";
    str ~= "\n\taddRouteList(\"hunt.application.staticfile.StaticfileController.doStaticFile\", &callHandler!(StaticfileController, \"doStaticFile\"));\n";
    
    foreach(memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember, T, memberName)) == function))
        {
            foreach (t;__traits(getOverloads, T, memberName))
            {
                static if (/*ParameterTypeTuple!(t).length == 0 && */ hasUDA!(t, Action))
                {
                    str ~= "\n\taddRouteList(\"" ~ moduleName ~ "." ~ T.stringof ~ "." ~ memberName  ~ "\",&callHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
                }
            }
        }
    }

    return str;
}

void callHandler(T, string fun)(Request req) if(is(T == class) || is(T == struct) && hasMember!(T,"__CALLACTION__"))
{
    T handler = new T();
    
	import core.memory;
	scope(exit){if(!handler.isAsync){handler.destroy(); GC.free(cast(void *)handler);}}

    //handler.before();		// It's already been called in line 183.
    req.action = fun;
    handler.callAction(fun, req);
    handler.after();		// Although the line 193 also has the code that calls after, but where has not executed, so this reservation
    handler.done();
}

HandleFunction getRouteFormList(string str)
{
    if (!_init)
    {
        _init = true;
    }

    return __routerList.get(str, null);
}

void addRouteList(string str, HandleFunction fun)
{
    //trace("add str is .... ", str);
    if(!_init)
    {
        import std.string : toLower;

        __routerList[str.toLower] = fun;
    }
}

private:
__gshared bool _init = false;
__gshared HandleFunction[string]  __routerList;
