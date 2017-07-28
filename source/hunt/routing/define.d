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

module hunt.routing.define;

public import std.experimental.logger;

public import hunt.http.request;

public import std.exception;

// default route group name
enum DEFAULT_ROUTE_GROUP = "default";

alias HandleFunction = void function(Request);

// support methods
enum HTTP_METHODS {
    GET = 1,
    POST,
    PUT,
    DELETE,
	HEAD,
	OPTIONS,
	PATCH,
	ALL
}

HTTP_METHODS getMethod(string method)
{
	with(HTTP_METHODS){
    if(method == "POST")
        return POST;
    else if (method == "GET")
        return GET;
    else if (method == "PUT")
        return PUT;
    else if (method == "DELETE")
        return DELETE;
    else if (method == "HEAD")
        return HEAD;
    else if (method == "OPTIONS")
        return OPTIONS;
    else if (method == "PATCH")
        return PATCH;
    else if (method == "*")
        return ALL;
    else 
        throw new Exception("unkonw method");
	}
}
HTTP_METHODS[] stringToHTTPMethods(string method)
{
	with(HTTP_METHODS){
    if(method == "POST")
        return [POST];
    else if (method == "GET")
        return [GET];
    else if (method == "PUT")
        return [PUT];
    else if (method == "DELETE")
        return [DELETE];
    else if (method == "HEAD")
        return [HEAD];
    else if (method == "OPTIONS")
        return [OPTIONS];
    else if (method == "PATCH")
        return [PATCH];
    else if (method == "*")
        return [GET,POST,PUT,DELETE,HEAD,OPTIONS,PATCH];
    else 
        throw new Exception("unkonw method");
	}
}
