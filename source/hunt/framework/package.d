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
public import hunt.entity;
public import hunt.validation;
public import hunt.util.MimeType;
public import hunt.util.worker;

public import hunt.http.codec.http;
public import hunt.http.codec.websocket;

public import hunt.framework.application;
public import hunt.framework.auth;
public import hunt.framework.breadcrumb;
public import hunt.framework.command.ServeCommand;
public import hunt.framework.controller;
public import hunt.framework.config;
public import hunt.framework.http;
public import hunt.framework.i18n.I18n;
public import hunt.framework.Init;
public import hunt.framework.middleware;
public import hunt.framework.provider;
public import hunt.framework.Simplify;
public import hunt.framework.queue;
public import hunt.framework.Version;
public import hunt.framework.view;


debug {}
else {
    import hunt.util.CompilerHelper;
    static assert(CompilerHelper.isGreaterThan(2082), 
        "The required version for D compiler must be greater than 2.083 if building in release model.");
}
