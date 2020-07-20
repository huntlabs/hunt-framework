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

module hunt.framework.middleware.MiddlewareInterface;

import hunt.framework.http.Request;
import hunt.framework.http.Response;

import hunt.logging.ConsoleLogger;
import hunt.Functions;

import std.exception;
import std.format;
import std.traits;

alias RouteChecker = Func2!(string, string, bool);
alias MiddlewareEventHandler = Func2!(MiddlewareInterface, Request, Response);

/**
 * 
 */
interface MiddlewareInterface
{
    ///get the middleware name
    string name();
    
    ///return null is continue, response is close the session
    Response onProcess(Request request, Response response = null);

    MiddlewareInterface rejectionHandler(MiddlewareEventHandler handler);
    
    MiddlewareEventHandler rejectionHandler();

    private __gshared TypeInfo_Class[string] _all;

    static void register(T)() if(is(T : MiddlewareInterface)) {
        string simpleName = T.stringof;
        auto itemPtr = simpleName in _all;
        if(itemPtr !is null) {
            warning("The middleware [%s] will be overwritten by [%s]", 
                itemPtr.name, T.classinfo.name);
        }

        _all[simpleName] = T.classinfo;
    }

    /**
     * Simple name
     */
    static TypeInfo_Class get(string name) {
        auto itemPtr = name in _all;
        if(itemPtr is null) {
            throw new Exception(format("The middleware %s has not been registered", name));
        }

        return *itemPtr;
    }

    static TypeInfo_Class[string] all() {
        return _all;
    }

    private __gshared MiddlewareEventHandler[string] _allRejectHanders;

    static void registerRejectHandler(T)(MiddlewareEventHandler handler) {
        string fullName = fullyQualifiedName!T;
        auto itemPtr = fullName in _allRejectHanders;
        if(itemPtr !is null) {
            warning("The middleware [%s]'s reject handler will be overwritten", fullName);
        }

        _allRejectHanders[fullName] = handler;
    }

    static void registerRejectHandler(string fullName, MiddlewareEventHandler handler) {
        auto itemPtr = fullName in _allRejectHanders;
        if(itemPtr !is null) {
            warning("The middleware [%s]'s reject handler will be overwritten", fullName);
        }

        _allRejectHanders[fullName] = handler;
    }

    static MiddlewareEventHandler getRejectHander(string fullName) {
        auto itemPtr = fullName in _allRejectHanders;
        if(itemPtr is null) {
            return null;
        }

        return *itemPtr;
    }
}

/**
 * 
 */
abstract class AbstractMiddleware(T) : MiddlewareInterface {

    protected RouteChecker _routeChecker;
    protected MiddlewareEventHandler _rejectionHandler;

    shared static this() {
        MiddlewareInterface.register!(T);
    }

    this() {
    }

    this(RouteChecker routeChecker, MiddlewareEventHandler rejectionHandler) {
        _routeChecker = routeChecker;
        _rejectionHandler = rejectionHandler;
    }

    MiddlewareInterface routeChecker(RouteChecker handler) {
        _routeChecker = handler;
        return this;
    }

    RouteChecker routeChecker() {
        return _routeChecker;
    }

    MiddlewareInterface rejectionHandler(MiddlewareEventHandler handler) {
        _rejectionHandler = handler;
        return this;
    }
    
    MiddlewareEventHandler rejectionHandler() {
        return _rejectionHandler;
    }

    // protected void onRejected() {
    //     if(_rejectionHandler !is null) {
    //         _rejectionHandler(this);
    //     }
    // }
    
    /// get the middleware name
    string name() {
        return typeid(this).name;
    }
    
    // Response onProcess(Request request, Response response = null) {
    //     version(HUNT_SHIRO_DEBUG) infof("path: %s, method: %s", request.path(), request.method );

    //     bool needCheck = true;
    //     if(_routeChecker !is null) {
    //         needCheck = _routeChecker(request.path(), request.getMethod());
    //     }

    //     if(!needCheck) {
    //         return null;
    //     }
    // }
}