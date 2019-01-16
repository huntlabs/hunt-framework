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

module hunt.framework;

public import hunt.cache;
public import hunt.util.MimeType;
public import hunt.validation;

public import hunt.http.codec.http;
public import hunt.http.codec.websocket;

public import hunt.framework.application;
public import hunt.framework.http;
public import hunt.framework.routing;
public import hunt.framework.task;
public import hunt.framework.view;

public import hunt.framework.Init;
public import hunt.framework.Version;
public import hunt.framework.Simplify;

debug {}
else {
    import hunt.util.Common;
    static assert(CompilerHelper.isGreater(2082), 
        "The version of D compiler must be greater than 2.083 in release model.");
}
