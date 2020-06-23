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
import hunt.framework.auth;
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
import hunt.http.HttpConnection;

import hunt.amqp.client;
import hunt.cache;
import hunt.entity.EntityManagerFactory;
import hunt.logging.ConsoleLogger;
import hunt.redis.Redis;
import hunt.redis.RedisPool;
import hunt.validation;

import poodinis;

import core.memory;
import core.thread;

import std.exception;
import std.string;
import std.traits;

struct Action {

}

private enum string TempVarName = "__var";
private enum string IndentString = "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t";  // 16 tabs

string indent(size_t number) {
    assert(number>0 && IndentString.length, "Out of range");
    return IndentString[0..number];
}


/**
 * 
 */
abstract class Controller
{
    private Request _request;
    private Response _response;

    protected
    {
        RoutingContext _routingContext;
        View _view;
        ///called before all actions
        MiddlewareInterface[string] middlewares;
    }

    Request request() {
        if(_request is null) {
            HttpConnection httpConnection = _routingContext.httpConnection();
            _request = new Request(_routingContext.getRequest(), httpConnection.getRemoteAddress(),
                _routingContext.groupName());
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
        assert(r !is null, "The response can't be null");
        _response = r;
        _routingContext.response = r.httpResponse;
    }

    /**
     * Get the currently authenticated user.
     */
    Identity user() {
        return this.request().user();
    }

    // AuthUser authenticate(string username, string password) {
    //     Request req = request();
    //     AuthUser user = req.user;
    //     user.authenticate(username, password);

    //     if(user.isAuthenticated()) {
    //         UserService userService = serviceContainer().resolve!UserService();
    //         string salt = userService.getSalt(username, password);
    //         string jwtToken = JwtUtil.sign(username, salt);
    //         Cookie tokenCookie = new Cookie("__auth_token__", jwtToken);
    //     }

    //     return user;
    // }


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
            version (HUNT_DEBUG) logDebugf("The %s is processing ...", m.name());

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

    ConstraintValidatorContext validate() {
        if(_context is null) {
            // assert(!_currentActionName.empty(), "No currentActionName found!");
            _context = new DefaultConstraintValidatorContext();

            auto itemPtr = _currentActionName in _actionValidators;
            // assert(itemPtr !is null, format("No handler found for action: %s!", _currentActionName));
            if(itemPtr is null) {
                warning(format("No validator found for action: %s.", _currentActionName));
            } else {
                try {
                    (*itemPtr)(_context);  
                } catch(Exception ex) {
                    warning(ex.msg);
                    version(HUNT_DEBUG) warning(ex);
                }
            }          
        }

        return _context;
    }
    private ConstraintValidatorContext _context;
    protected string _currentActionName;
    protected QueryParameterValidator[string] _actionValidators;

    protected void done() {
        Request req = request();
        req.flush(); // assure the sessiondata flushed;
        Response resp = response();
        HttpSession session = req.session(false);
        if (session !is null ) // && session.isNewSession()
        {
            resp.withCookie(new Cookie(DefaultSessionIdName, session.getId(), session.getMaxInactiveInterval(), 
                    "/", null, false, false));
        }

        resp.header("Date", date("Y-m-d H:i:s"));
        resp.header(HttpHeader.X_POWERED_BY, HUNT_X_POWERED_BY);
        resp.header(HttpHeader.SERVER, HUNT_FRAMEWORK_SERVER);

        if(!resp.getFields().contains(HttpHeader.CONTENT_TYPE)) {
            resp.header(HttpHeader.CONTENT_TYPE, MimeType.TEXT_HTML_VALUE);
        }

        if(req.canRememberMe() && !req.authToken().empty) {
            Cookie tokenCookie = new Cookie(JwtUtil.COOKIE_NAME, req.authToken());
            resp.withCookie(tokenCookie);
        } else if(req.isLogout()) {
            Cookie tokenCookie = new Cookie(JwtUtil.COOKIE_NAME, "", 0);
            resp.withCookie(tokenCookie);
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
    // Predefined characteristic name for a default Action method.
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
    

    string str = `

        import hunt.http.server.HttpServerRequest;
        import hunt.http.server.HttpServerResponse;
        import hunt.http.routing.RoutingContext;
        import hunt.http.HttpBody;
        import hunt.logging.ConsoleLogger;
        import hunt.validation.ConstraintValidatorContext;
        import std.demangle;

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
            static foreach (currentMethod; __traits(getOverloads, T, memberName))
            {
                // alias RT = ReturnType!(t);

                //alias pars = ParameterTypeTuple!(t);
                static if (hasUDA!(currentMethod, Action) || _isActionMember) {
                    str ~= indent(2) ~ "case \"" ~ memberName ~ "\": {\n";
                    str ~= indent(4) ~ "_currentActionName = \"" ~ currentMethod.mangleof ~ "\";";

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

                    // Action parameters
                    auto params = ParameterIdentifierTuple!currentMethod;
                    string paramString = "";

                    static if (params.length > 0) {
                        import std.conv : to;

                        string varName = "";
                        alias paramsType = Parameters!currentMethod;

                        static foreach (int i; 0..params.length)
                        {
                            varName = TempVarName ~ i.to!string;

                            static if (paramsType[i].stringof == "string") {
                                str ~= indent(2) ~ "string " ~ varName ~ " = request.get(\"" ~ params[i] ~ "\");\n";
                            } else static if (isNumeric!(paramsType[i])) {
                                str ~= "\t\tauto " ~ varName ~ " = this.processGetNumericString(request.get(\"" ~ 
                                    params[i] ~ "\")).to!" ~ paramsType[i].stringof ~ ";\n";
                            } else static if(is(paramsType[i] : Form)) {
                                str ~= "\t\tauto " ~ varName ~ " = request.bindForm!" ~ paramsType[i].stringof ~ "();\n";
                            } else {
                                str ~= "\t\tauto " ~ varName ~ " = request.get(\"" ~ params[i] ~ "\").to!" ~ 
                                        paramsType[i].stringof ~ ";\n";
                            }

                            paramString ~= i == 0 ? varName : ", " ~ varName;
                            // varName = "";
                        }
                    }

                    // Parameters validation
                    // https://forum.dlang.org/post/bbgwqvvausncrkukzpui@forum.dlang.org
                    str ~= indent(3) ~ `_actionValidators["` ~ currentMethod.mangleof ~ 
                        `"] = (ConstraintValidatorContext context) {` ~ "\n";

                    static if(is(typeof(currentMethod) allParams == __parameters)) {
                        str ~= indent(4) ~ "version(HUNT_DEBUG) info(`Validating in " ~  memberName ~ 
                            ", the prototype is " ~ typeof(currentMethod).stringof ~ ". `); " ~ "\n";
                        // str ~= indent(4) ~ `version(HUNT_DEBUG) infof("Validating in %s", demangle(_currentActionName)); ` ~ "\n";                        

                        static foreach(i, _; allParams) {{
                            alias thisParameter = allParams[i .. i + 1]; 
                            alias udas =  __traits(getAttributes, thisParameter);
                            enum ident = __traits(identifier, thisParameter);

                            str ~= "\n" ~ makeParameterValidation!(TempVarName ~ i.to!string, ident, 
                                thisParameter, udas) ~ "\n"; 
                         }}
                    }

                    str ~= indent(3) ~ "};\n";

                    // Call the Action
                    static if (is(ReturnType!currentMethod == void)) {
                        str ~= "\t\tthis." ~ memberName ~ "(" ~ paramString ~ ");\n";
                    } else {
                        str ~= "\t\t" ~ ReturnType!currentMethod.stringof ~ " result = this." ~ 
                                memberName ~ "(" ~ paramString ~ ");\n";

                        static if (is(ReturnType!currentMethod : Response)) {
                            str ~= "\t\t response = result;\n";
                        } else {
                            str ~="\t\tthis.response.setContent(result);";
                        }
                    }

                    // str ~= "\t\tactionResponse = this.processResponse(actionResponse);\n";

                    static if(hasUDA!(currentMethod, Action) || _isActionMember) {
                        str ~= "\n\t\tthis.after();\n";
                    }

                    str ~= "\n\t\tbreak;\n\t}\n";
                }
            }
        }
    }

    str ~= "\tdefault:\n\tbreak;\n\t}\n\n";
    // str ~= "this.done();";
    str ~= "}";

    return str;
}


string makeParameterValidation(string varName, string paraName, paraType, UDAs ...)() {
    string str;
    // = "\ninfof(\"" ~ symbol.stringof ~ "\");";

    static foreach(uda; UDAs) {
        static if(is(typeof(uda) == Max)) {
            str ~= `
                MaxValidator validator = new MaxValidator();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }

        static if(is(typeof(uda) == Min)) {
            str ~= `
                MinValidator validator = new MinValidator();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }

        static if(is(typeof(uda) == AssertFalse)) {
            str ~= `
                AssertFalseValidator validator = new AssertFalseValidator();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }

        static if(is(typeof(uda) == AssertTrue)) {
            str ~= `
                AssertTrueValidator validator = new AssertTrueValidator();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }

        static if(is(typeof(uda) == Email)) {
            str ~= `
                EmailValidator validator = new EmailValidator();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }

        static if(is(typeof(uda) == Length)) {
            str ~= `
                LengthValidator validator = new LengthValidator();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }

        static if(is(typeof(uda) == NotBlank)) {
            str ~= `
                NotBlankValidator validator = new NotBlankValidator();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }

        static if(is(typeof(uda) == NotEmpty)) {
            str ~= `
                auto validator = new NotEmptyValidator!` ~ paraType.stringof ~`();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }

        static if(is(typeof(uda) == Pattern)) {
            str ~= `
                PatternValidator validator = new PatternValidator();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }

        static if(is(typeof(uda) == Size)) {
            str ~= `
                SizeValidator validator = new SizeValidator();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }

        static if(is(typeof(uda) == Range)) {
            str ~= `
                RangeValidator validator = new RangeValidator();
                validator.initialize(` ~ uda.stringof ~ `);
                validator.setPropertyName("` ~ paraName ~ `");
                validator.isValid(`~ varName ~`, context);
            `;
        }
    }

    return str;
}

alias QueryParameterValidator = void delegate(ConstraintValidatorContext);

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
    // req.action = method;
    // auto req = context.getRequest();
    // warningf("group name: %s, Threads: %d", context.groupName(), Thread.getAll().length);

    T controller = new T();

    scope(exit) {
        controller.dispose();        
        version(HUNT_THREAD_DEBUG) warningf("Threads: %d", Thread.getAll().length);
        resetWorkerThread();
    }

    try {
        controller.callActionMethod(method, context);
    } catch (Throwable t) {
        error(t);
        Response errorRes = new Response();
        errorRes.doError(HttpStatus.INTERNAL_SERVER_ERROR_500, t);
        controller.response = errorRes; 
    }
    
    controller.done();
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
