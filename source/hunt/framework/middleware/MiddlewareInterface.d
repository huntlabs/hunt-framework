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

import hunt.logging.Logger;
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

}

/**
 * 
 */
abstract class AbstractMiddleware : MiddlewareInterface {
    
    /// get the middleware name
    string name() {
        return typeid(this).name;
    }
}