/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.controller.Controller;

import hunt.framework.application.Application;
import hunt.framework.breadcrumb.BreadcrumbsManager;
import hunt.framework.middleware.MiddlewareInterface;

import hunt.framework.http.Request;
import hunt.framework.http.Form;
import hunt.framework.i18n.I18n;
import hunt.framework.provider;
import hunt.framework.Simplify;
import hunt.framework.view;

public import hunt.framework.http.Response;
public import hunt.http.server;
public import hunt.http.routing;

import hunt.amqp.client;
import hunt.cache;
import hunt.entity.EntityManagerFactory;
import hunt.logging.ConsoleLogger;
import hunt.redis.Redis;
import hunt.redis.RedisPool;
import hunt.validation;

import poodinis;

import std.exception;
import std.string;
import std.traits;

enum Action;

/**
 * 
 */
abstract class Controller
{
    private Request _request;
    private Response _response;
    private EntityManager _entityManager;
    private BreadcrumbsManager _breadcrumbs;
    private AmqpConnection _amqpConnection;

    protected
    {
        RoutingContext _routingContext;
        View _view;
        ///called before all actions
        MiddlewareInterface[string] middlewares;
    }

    // shared(DependencyContainer) serviceContainer() {
    //     return .serviceContainer();
    // }

    Request request() {
        if(_request is null) {
            _request = new Request(_routingContext.getRequest(), _routingContext.groupName());
        }
        return _request;
    }

    final @property Response response() {
        if(_response is null) {
            _response = new Response(_routingContext.getResponse());
        }
        return _response;
    }

    // reset to a new response
    @property void response(Response r) {
        _response = r;
        _routingContext.response = r.httpResponse;
    }

    @property View view()
    {
        if (_view is null)
        {
            _view = serviceContainer.resolve!View();
            _view.setRouteGroup(_routingContext.groupName());
            _view.setLocale(this.request.locale());
        }

        return _view;
    }

    BreadcrumbsManager breadcrumbsManager() {
        if(_breadcrumbs is null) {
            _breadcrumbs = serviceContainer.resolve!BreadcrumbsManager();
        }
        return _breadcrumbs;
    }

    I18n translationManager() {
        return serviceContainer.resolve!(I18n);
    }

    Cache cache() {
        return serviceContainer.resolve!(Cache);
    }    
    
    Redis redis() {
        RedisPool pool = serviceContainer.resolve!RedisPool();
        return pool.getResource();
    }

    EntityManager entityManager() {
        if(_entityManager is null) {
            _entityManager = serviceContainer.resolve!(EntityManagerFactory).currentEntityManager();
        }
        return _entityManager;
    }

    AmqpConnection amqpConnection() {
        if(_amqpConnection is null) {
           AmqpClient amqpClient = serviceContainer.resolve!AmqpClient();
           _amqpConnection = amqpClient.connect();
        }

        return _amqpConnection;
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
        if(m is null || this.middlewares.get(m.name(), null) !is null)
        {
            return false;
        }

        this.middlewares[m.name()]= m;
        return true;
    }

    // get all middleware
    MiddlewareInterface[string] getMiddlewares()
    {
        return this.middlewares;
    }

    protected final Response doMiddleware()
    {
        version (HUNT_DEBUG) logDebug("doMiddlware ..");

        // TODO: Tasks pending completion -@zhangxueping at 2020-01-02T18:24:39+08:00
        // 

        foreach (m; middlewares)
        {
            version (HUNT_DEBUG) logDebugf("do %s onProcess ..", m.name());

            auto response = m.onProcess(this.request, this.response);
            if (response is null)
            {
                continue;
            }

            version (HUNT_DEBUG) logDebugf("Middleware %s is to retrun.", m.name);
            return response;
        }

        return null;
    }

    // @property bool isAsync()
    // {
    //     return true;
    // }

    string processGetNumericString(string value)
    {
        import std.string;

        if (!isNumeric(value))
        {
            return "0";
        }

        return value;
    }

    Response processResponse(Response res)
    {
        // TODO: Tasks pending completion -@zhangxueping at 2020-01-06T14:01:43+08:00
        // 
        // have ResponseHandler binding?
        // if (res.httpResponse() is null)
        // {
        //     res.setHttpResponse(request.responseHandler());
        // }

        return res;
    }

    protected void done() {
        if(_amqpConnection !is null) {
            _amqpConnection.close(null);
        }
        request().flush(); // assure the sessiondata flushed;
        Response resp = response();
        HttpSession session = request().session(false);
        if (session !is null ) // && session.isNewSession()
        {
            resp.withCookie(new Cookie(DefaultSessionIdName, session.getId(), session.getMaxInactiveInterval(), 
                    "/", null, false, false));
        }

        resp.header("Date", date("Y-m-d H:i:s"));
        resp.header(HttpHeader.X_POWERED_BY, HUNT_X_POWERED_BY);

        if(!resp.getFields().contains(HttpHeader.CONTENT_TYPE)) {
            resp.header(HttpHeader.CONTENT_TYPE, MimeType.TEXT_HTML_VALUE);
        }
    }

    void dispose() {
        version(HUNT_HTTP_DEBUG) trace("Do nothing");
    }
}

mixin template MakeController(string moduleName = __MODULE__)
{
    mixin HuntDynamicCallFun!(typeof(this), moduleName);
}

mixin template HuntDynamicCallFun(T, string moduleName) if(is(T : Controller))
{
public:
    enum allActions = __createCallActionMethod!(T, moduleName);
    // version (HUNT_DEBUG) 
    // pragma(msg, allActions);

    mixin(allActions);
    
    shared static this()
    {
        enum routemap = __createRouteMap!(T, moduleName);
        // pragma(msg, routemap);
        mixin(routemap);
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

string __createCallActionMethod(T, string moduleName)()
{
    import std.traits;
    import std.format;
    import std.string;
    import std.conv;
    
    import hunt.logging.ConsoleLogger;

    string str = `

        import hunt.http.server.HttpServerRequest;
        import hunt.http.server.HttpServerResponse;
        import hunt.http.routing.RoutingContext;
        import hunt.http.HttpBody;

        void callActionMethod(string methodName, RoutingContext context) {
            _routingContext = context;
            Response actionResponse=null;
            HttpBody rb;
            version (HUNT_FM_DEBUG) logDebug("methodName=", methodName);
            import std.conv;

            switch(methodName){
    `;

    foreach (memberName; __traits(allMembers, T))
    {
        // TODO: Tasks pending completion -@zhangxueping at 2019-09-24T11:47:45+08:00
        // Can't detect the error: void test(error);
        // pragma(msg, "memberName: ", memberName);
        static if (is(typeof(__traits(getMember, T, memberName)) == function))
        {
            // pragma(msg, "got: ", memberName);

            enum _isActionMember = isActionMember(memberName);
            foreach (t; __traits(getOverloads, T, memberName))
            {
                // alias RT = ReturnType!(t);

                //alias pars = ParameterTypeTuple!(t);
                static if (hasUDA!(t, Action) || _isActionMember)
                {
                    str ~= "\t\tcase \"" ~ memberName ~ "\": {\n";

                    static if (hasUDA!(t, Action) || _isActionMember)
                    {
                        //before
                        str ~= q{
                            if(this.getMiddlewares().length) {
                                auto middleResponse = this.doMiddleware();

                                if (middleResponse !is null) {
                                    // _routingContext.response = response.httpResponse;
                                    response = middleResponse;
                                    return;
                                }
                            }

                            if (!this.before()) {
                                // _routingContext.response = response.httpResponse;
                                // response = middleResponse;
                                return;
                            }
                        };
                    }

                    // Action parameters
                    auto params = ParameterIdentifierTuple!t;
                    string paramString = "";

                    static if (params.length > 0)
                    {
                        import std.conv : to;

                        string varName = "";
                        alias paramsType = Parameters!t;

                        static foreach (int i; 0..params.length)
                        {
                            varName = "var" ~ i.to!string;

                            static if (paramsType[i].stringof == "string")
                            {
                                str ~= "\t\tstring " ~ varName ~ " = request.get(\"" ~ params[i] ~ "\");\n";
                            }
                            else
                            {
                                static if (isNumeric!(paramsType[i])) {
                                    str ~= "\t\tauto " ~ varName ~ " = this.processGetNumericString(request.get(\"" ~ 
                                        params[i] ~ "\")).to!" ~ paramsType[i].stringof ~ ";\n";
                                } else static if(is(paramsType[i] : Form)) {
                                    str ~= "\t\tauto " ~ varName ~ " = request.bindForm!" ~ paramsType[i].stringof ~ "();\n";
                                } else {
                                    str ~= "\t\tauto " ~ varName ~ " = request.get(\"" ~ params[i] ~ "\").to!" ~ 
                                            paramsType[i].stringof ~ ";\n";
                                }
                            }

                            paramString ~= i == 0 ? varName : ", " ~ varName;

                            varName = "";
                        }
                    }

                    // call Action
                    static if (is(ReturnType!t == void)) {
                        str ~= "\t\tthis." ~ memberName ~ "(" ~ paramString ~ ");\n";
                    } else {
                        str ~= "\t\t" ~ ReturnType!t.stringof ~ " result = this." ~ 
                                memberName ~ "(" ~ paramString ~ ");\n";

                        static if (is(ReturnType!t : Response))
                        {
                            str ~= "\t\t response = result;\n";
                        }
                        else
                        {
                            str ~="\t\tthis.response.setContent(result);";
                        }
                    }

                    // str ~= "\t\tactionResponse = this.processResponse(actionResponse);\n";

                    static if(hasUDA!(t, Action) || _isActionMember)
                    {
                        str ~= "\t\tthis.after();\n";
                    }
                    str ~= "\n\t\tbreak;\n\t}\n";
                }
            }
        }
    }

    str ~= "\tdefault:\n\tbreak;\n\t}\n\n";
    str ~= "this.done();";
    str ~= "}";

    return str;
}

string __createRouteMap(T, string moduleName)()
{

    enum len = "Controller".length;
    enum controllerName = moduleName[0..$-len];

    // The format: 
    // 1) app.controller.{group}.{name}controller
    //      app.controller.admin.IndexController
    // 2) app.component.{component-name}.controller.{group}.{name}controller
    //      app.component.system.controller.admin.DashboardController
    enum string[] parts = moduleName.split(".");
    // string groupName = "default";

    static if(parts.length == 4) {
        // app.controller.admin.DashboardController
        enum GroupName = parts[2];
    } else static if(parts.length == 6) {
        // app.component.system.controller.admin.DashboardController
        enum GroupName = parts[4];
    } else {
        enum GroupName = "default";
    }

    string str = "";
    foreach (memberName; __traits(allMembers, T))
    {
        // pragma(msg, "memberName: ", memberName);

        static if (is(typeof(__traits(getMember, T, memberName)) == function)) {
            foreach (t; __traits(getOverloads, T, memberName)) {
                static if (hasUDA!(t, Action)) {
                    enum string MemberName = memberName;
                } else static if (isActionMember(memberName)) {
                    enum string MemberName = memberName[0 .. $ - actionNameLength];
                } else {
                    enum string MemberName = "";
                }

                static if(MemberName.length > 0) {
                    str ~= "\n\tregisterRouteHandler(\"" ~ controllerName ~ "." ~ T.stringof ~ "." ~ MemberName
                        ~ "\", (context) { 
                            context.groupName = \"" ~ GroupName ~ "\";
                            callHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\")(context);
                    });\n";
                }
            }
        }
    }

    return str;
}

void callHandler(T, string method)(RoutingContext context)
        if (is(T == class) || (is(T == struct) && hasMember!(T, "__CALLACTION__")))
{
    T controller = new T();
    import core.memory;
    scope(exit) {
        controller.dispose();
        // if(!controller.isAsync) { 
        //     controller.destroy(); 
        //     GC.free(cast(void *)controller);
        // }
    }

    // req.action = method;
    // auto req = context.getRequest();
    // warningf("group name: %s", context.groupName());
    try {
        controller.callActionMethod(method, context);
    } catch (Throwable t) {
        warning(t.msg);
        version(HUNT_DEBUG) warning(t);
        controller.response.doError(HttpStatus.INTERNAL_SERVER_ERROR_500, t.msg);
    }

    context.end();
}

RoutingHandler getRouteHandler(string str)
{
    return _actions.get(str, null);
}

void registerRouteHandler(string str, RoutingHandler method)
{
    // key: app.controller.Index.IndexController.showString
    version (HUNT_FM_DEBUG) logDebug("Add route handler: ", str);
    _actions[str.toLower] = method;
}

__gshared RoutingHandler[string] _actions;
