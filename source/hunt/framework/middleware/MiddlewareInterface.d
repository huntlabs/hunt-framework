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

import hunt.Functions;

alias RouteChecker = Func2!(string, string, bool);
alias MiddlewareEventHandler = Func2!(AbstractMiddleware, Request, Response);

/**
 * 
 */
interface MiddlewareInterface
{
    ///get the middleware name
    string name();
    
    ///return null is continue, response is close the session
    Response onProcess(Request request, Response response = null);
}

/**
 * 
 */
abstract class AbstractMiddleware : MiddlewareInterface {

    protected RouteChecker _routeChecker;
    protected MiddlewareEventHandler _rejectionHandler;

    this() {
    }

    this(RouteChecker routeChecker, MiddlewareEventHandler rejectionHandler) {
        _routeChecker = routeChecker;
        _rejectionHandler = rejectionHandler;
    }

    AbstractMiddleware routeChecker(RouteChecker handler) {
        _routeChecker = handler;
        return this;
    }

    RouteChecker routeChecker() {
        return _routeChecker;
    }

    AbstractMiddleware rejectionHandler(MiddlewareEventHandler handler) {
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