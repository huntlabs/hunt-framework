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

module hunt.router.define;

public import std.experimental.logger;

public import hunt.http.request;

// default route group name
enum DEFAULT_ROUTE_GROUP = "default";

alias HandleFunction = void function(Request);

// support methods
enum HTTP_METHOS {
    GET = 1,
    POST,
    PUT,
    DELETE
}
