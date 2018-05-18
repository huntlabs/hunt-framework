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

import kiss.logger;

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
    }

    private
    {
        Response _response;
        View _view;
    }

    /*
    // session from request, plaese!
    final @property session()
    {
        return request.getSession();
    }
    */
    
    final @property Response response()
    {
        if (this._response is null)
            request.createResponse();

        return this._response;
    }

    /// called before action  return true is continue false is finish
    // bool before(){return true;}
    bool before()
	{
		/**
		CORS support
		http://www.cnblogs.com/feihong84/p/5678895.html
		https://stackoverflow.com/questions/10093053/add-header-in-ajax-request-with-jquery
		*/

        // FIXME: Needing refactor or cleanup -@zxp at 5/10/2018, 11:33:11 AM
        // set this through the configuration
		response.setHeader("Access-Control-Allow-Origin", "*");
		response.setHeader("Access-Control-Allow-Methods", "*");
		response.setHeader("Access-Control-Allow-Headers", "*");

		if ( cmp(toUpper(request.method),"OPTIONS") == 0)
		{
			return false;
		}
			
		return true;
	}

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

    protected final Response doMiddleware()
    {
        logDebug("doMiddlware ..");

        foreach(m; middlewares)
        {
           logDebugf("do %s onProcess ..", m.name());

            auto response = m.onProcess(this.request, this.response);
            if(response is null)
            {
                continue;
            }

            logDebugf("Middleware %s is to retrun.", m.name);
            return response;
        }

        return null;
    }

	@property bool isAsync()
	{
		return true;
	}
}

mixin template MakeController(string moduleName = __MODULE__)
{
    mixin HuntDynamicCallFun!(typeof(this), moduleName);
}

mixin template HuntDynamicCallFun(T, string moduleName)
{
public:
    mixin(__createCallActionFun!(T, moduleName));
    shared static this()
    {
        mixin(__createRouteMap!(T, moduleName));
    }
}

string  __createCallActionFun(T, string moduleName)()
{
    import std.traits;
    import std.format;

    string str = "Response callAction(string funName, Request req) {";
    str ~= "\n\tptr.request = req;";
    str ~= "\n\tswitch(funName){";
    
    foreach(memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
        {
            foreach (t; __traits(getOverloads, T, memberName)) 
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
                            str ~= format("this.addMiddleware(new %s);", middleware.className);
                        }
                    }

                    str ~= "Response res = this.doMiddleware()\n";
                    str ~= "if(response !is null) {return res;}\n";

                    //action
                    static if (typeof(t) == hunt.http.response.Response)
                    {
                        str ~= "return this." ~ memberName ~ "();\n";
                    }
                    else static if (typeof(t) == std.json.JSONValue)
                    {
                        str ~= "return this.response.setContent(this." ~ memberName ~ "().toString());\n";
                    }
                    else static if (typeof(t) == string)
                    {
                        str ~= "return this.response.setContent(this." ~ memberName ~ "());\n";
                    }
                    else static if (typeof(t) == void)
                    {
                        // nothing to do?!
                        str ~= "return this.response;\n";
                    }
                    else
                    {
                        // What do you want?!
                        str ~= "import std.conv : to;\n";
                        str ~= "return this.response.setContent(this." ~ memberName ~ "().to!string);\n";
                    }

                    str ~= "}\n break;";
                }
            }
        }
    }

    str ~= "default : break;}";
    str ~= "return this.response;";
    str ~= "}";

    return str;
}

string  __createRouteMap(T, string moduleName)()
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

Response callHandler(T, string method)(Request req) if(is(T == class) || is(T == struct) && hasMember!(T,"__CALLACTION__"))
{
    T controller = new T();
    
	// import core.memory;
	// scope(exit){if(!controller.isAsync){controller.destroy(); GC.free(cast(void *)controller);}}

    controller.before();
    req.action = method;
    Response response = controller.callAction(method, req);
    controller.after();		// Although the line 193 also has the code that calls after, but where has not executed, so this reservation

    return response;
}

HandleFunction getRouteFromList(string str)
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
