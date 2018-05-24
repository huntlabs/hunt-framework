/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Website: www.huntframework.com
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
import hunt.view;

import std.exception;
import std.traits;

enum Action;

/*
struct Middleware
{
    string className;
}
*/

abstract class Controller
{
    protected
    {
        Request request;
        Response _response;
        ///called before all actions
        MiddlewareInterface[] middlewares;
    }

    @property View view()
    {
        return GetViewInstance();
    }

    final @property Response response()
    {
        if (_response is null)
            _response = request.createResponse();
        return _response;
    }

    /// called before action  return true is continue false is finish
    bool before()
    {
        return true;
    }

    /// called after action  return true is continue false is finish
    bool after()
    {
        return true;
    }

    ///add middleware
    ///return true is ok, the named middleware is already exist return false
    bool addMiddleware(MiddlewareInterface m)
    {
        if (m is null)
            return false;
        foreach (tmp; this.middlewares)
        {
            if (tmp.name == m.name)
                return false;
        }

        this.middlewares ~= m;
        return true;
    }

    // get all middleware
    MiddlewareInterface[] getMiddlewares()
    {
        return this.middlewares;
    }

    @property UCache cache()
    {
        return Application.getInstance().getCache();
    }

    @property cacheManger()
    {
        return Application.getInstance().getCacheManger();
    }

    protected final Response doMiddleware()
    {
        debug logDebug("doMiddlware ..");

        foreach (m; middlewares)
        {
            debug logDebugf("do %s onProcess ..", m.name());

            auto response = m.onProcess(this.request, this.response);
            if (response is null)
            {
                continue;
            }

            debug logDebugf("Middleware %s is to retrun.", m.name);
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
    version (HuntDebugMode) pragma(msg, __createCallActionFun!(T, moduleName));
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
        return name.length > actionNameLength && name[$ - actionNameLength .. $] == actionName;
    }
}

string __createCallActionFun(T, string moduleName)()
{
    import std.traits;
    import std.format;
    import std.string;
    import kiss.logger;

    string str = `
        Response callAction(string funName, Request req) {
        this.request = req; 
        Response actionResult=null;
        version (HuntDebugMode) logDebug("funName=", funName);
        switch(funName){
    `;

    foreach (memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember, T, memberName)) == function))
        {
            enum _isActionMember = isActionMember(memberName);
            foreach (t; __traits(getOverloads, T, memberName))
            {
                version (HuntDebugMode) pragma(msg, "memberName: " ~ memberName);

                //alias pars = ParameterTypeTuple!(t);
                static if (hasUDA!(t, Action) || hasUDA!(t, Route) || _isActionMember)
                {
                    str ~= "case \"" ~ memberName ~ "\": {\n";

                    static if (hasUDA!(t, Action) || _isActionMember)
                    {
                        /*
                        // middleware
                        enum middlewares = getUDAs!(t, Middleware);
                        static if (middlewares.length)
                        {
                            foreach (i, middleware; middlewares)
                            {
                                str ~= format("this.addMiddleware(new %s);", middleware.className);
                            }
                        }
                        */

                        //before
                        str ~= q{
                            if(this.getMiddlewares().length){
                                auto response = this.doMiddleware();
                                if (response !is null)
                                {
                                    return response;
                                }
                            }
                            this.before();
                        };
                    }

                    //action
                    static if (is(ReturnType!t == void))
                    {
                        str ~= "this." ~ memberName ~ "(); actionResult = req.createResponse();";
                        version (HuntDebugMode) pragma(msg, "no return value for " ~ memberName);
                    }
                    else
                    {
                        version (HuntDebugMode) pragma(msg,
                                "return type is: " ~ ReturnType!t.stringof ~ " for " ~ memberName);
                        str ~= ReturnType!t.stringof ~ " result = this." ~ memberName ~ "();";
                        static if (is(ReturnType!t : Response))
                        {
                            str ~= q{
                                actionResult = result;
                            };
                        }
                        else
                        {
                            str ~= q{
                                actionResult = new Response(); // req.createResponse(); 
                                actionResult.setContent(to!string(result));
                            };
                        }
                    }

                    static if(hasUDA!(t, Action) || _isActionMember){
                        str ~= `if(!this.after()) { return null; }`;
                    }
                    str ~= "} break;";
                }
            }
        }
    }

    str ~= "default : break;}";
    str ~= "return actionResult;";
    str ~= "}";

    // pragma(msg, str);

    return str;
}

string __createRouteMap(T, string moduleName)()
{
    string str = "";

    //pragma(msg, "moduleName", moduleName);
    str ~= "\n\timport hunt.application.staticfile;\n";
    str ~= "\n\taddRouteList(\"hunt.application.staticfile.StaticfileController.doStaticFile\", &callHandler!(StaticfileController, \"doStaticFile\"));\n";

    foreach (memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember, T, memberName)) == function))
        {
            foreach (t; __traits(getOverloads, T, memberName))
            {
                static if ( /*ParameterTypeTuple!(t).length == 0 && */ hasUDA!(t, Action))
                {
                    str ~= "\n\taddRouteList(\"" ~ moduleName ~ "." ~ T.stringof ~ "." ~ memberName
                        ~ "\",&callHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
                }
                else static if (isActionMember(memberName))
                {
                    enum strippedMemberName = memberName[0 .. $ - actionNameLength];
                    str ~= "\n\taddRouteList(\"" ~ moduleName ~ "." ~ T.stringof ~ "." ~ strippedMemberName
                        ~ "\",&callHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
                }
            }
        }
    }

    return str;
}

Response callHandler(T, string method)(Request req)
        if (is(T == class) || is(T == struct) && hasMember!(T, "__CALLACTION__"))
{
    T controller = new T();
    import core.memory;
    scope(exit){if(!controller.isAsync){controller.destroy(); GC.free(cast(void *)controller);}}

    req.action = method;
    return controller.callAction(method, req);
}

HandleFunction getRouteFromList(string str)
{
    if (!_init)
        _init = true;
    return __routerList.get(str, null);
}

void addRouteList(string str, HandleFunction method)
{
    version (HuntDebugMode)
        logDebug("add router: ", str);
    if (!_init)
    {
        import std.string : toLower;
        __routerList[str.toLower] = method;
    }
}

private:
__gshared bool _init = false;
__gshared HandleFunction[string] __routerList;
