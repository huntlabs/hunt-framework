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
        MiddlewareInterface[] middlewares;
    }

    private
    {
        Response _response;
        //View _view;
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
    bool addMiddleware(MiddlewareInterface m)
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
    MiddlewareInterface[] getMiddlewares()
    {
        return this.middlewares;
    }

    //view render
    // @property View view()
    // {
    //     if(_view is null)
    //     {
    //         _view = new View();
    //     }
    //     return _view;
    // }

    @property UCache cache()
    {
		return Application.getInstance().getCache();
    }

	@property cacheManger()
	{
		return Application.getInstance().getCacheManger();
	}

    // void render(string filename = null)()
    // {
    //     this.response.html(this.view.render!filename());
    // }

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
    //pragma(msg, __createCallActionFun!(T, moduleName));
    mixin(__createCallActionFun!(T, moduleName));
    shared static this()
    {
        mixin(__createRouteMap!(T, moduleName));
    }
}


private
{
    enum actionName = "Action";
    enum actionNameLength = actionName.length;

    bool isActionMember(string name)
    {
        return name.length > actionNameLength && name[$-actionNameLength .. $] == actionName;
    }
}

alias ActionReturnEventHandler = void delegate(Controller sender, string v);


string  __createCallActionFun(T, string moduleName)()
{
    import std.traits;
    import std.format;
    import std.string;
    import std.experimental.logger;

    string str = "bool callAction(string funName, Request req, ActionReturnEventHandler handler = null) {";
    str ~= "\n\tauto ptr = this; ptr.request = req; bool r = false; string actionResult=null;";
    version(HuntDebugMode) str ~= `trace("funName=", funName);`;
    str ~= "\n\tswitch(funName){";


    foreach(memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
        {
            enum _isActionMember = isActionMember(memberName);
            foreach (t;__traits(getOverloads,T,memberName)) 
            {
                 version(HuntDebugMode) pragma(msg, "memberName: " ~ memberName);

                //alias pars = ParameterTypeTuple!(t);
                static if( hasUDA!(t, Action) || hasUDA!(t, Route) || _isActionMember)
                {
                    str ~= "case \"" ~ memberName  ~ "\": {\n";

                    static if(hasUDA!(t, Action) || _isActionMember)
                    {
                        // middleware
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
                    static if(is(ReturnType!t : void))
                    {
                        str ~= "ptr." ~ memberName ~ "();";
                        pragma(msg, "no return value for " ~ memberName);
                        // version(HuntDebugMode)
                    }
                    else 
                    {
                        pragma(msg, "return type is: " ~ ReturnType!t.stringof ~ " for " ~ memberName);
                        str ~= ReturnType!t.stringof ~ " result = ptr." ~ memberName ~ "();";
                        static if(is(ReturnType!t : Response))
                        {   
                            // str ~= "actionResult = result.getContent();";
                        }
                        else
                            str ~= "actionResult = to!string(result);";
                    }

                    str ~= "if(handler !is null)  handler(this, actionResult);";

                    str ~= "r = true;";

                    // static if(hasUDA!(t, Action) || _isActionMember){
                    //     //after
                    //     str ~= q{
                    //         if(!ptr.after()){return false;}
                    //     };
                    // }
                    str ~= "}\n break;";
                }
                str ~= "}\nbreak;\n";
            }
        }
    }

    str ~= "default : break;}";
    str ~= "return r;";
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
                else static if(memberName.length > actionNameLength && memberName[$-actionNameLength .. $] == actionName)
                {   
                    enum strippedMemberName =  memberName[0 .. $-actionNameLength];
                    str ~= "\n\taddRouteList(\"" ~ moduleName ~ "." ~ T.stringof ~ "." ~ strippedMemberName  ~ "\",&callHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
                }
            }
        }
    }

    return str;
}

void callHandler(T, string fun)(Request req) if(is(T == class) || is(T == struct) && hasMember!(T,"__CALLACTION__"))
{

    void onActionDone(Controller sender, string result)
    {
        sender.response.html(result);
    }

    T controller = new T();
    
	import core.memory;
	scope(exit){if(!controller.isAsync){controller.destroy(); GC.free(cast(void *)controller);}}

    //controller.before();		// It's already been called in line 183.
    req.action = fun;
    bool r = controller.callAction(fun, req, &onActionDone);
    if(r)
        controller.after();		// Although the line 193 also has the code that calls after, but where has not executed, so this reservation
    controller.done();

    // return controller.response;
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
    trace("add str is .... ", str);
    if(!_init)
    {
        import std.string : toLower;

        __routerList[str.toLower] = fun;
    }
}

private:
__gshared bool _init = false;
__gshared HandleFunction[string]  __routerList;
