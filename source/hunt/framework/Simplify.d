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

module hunt.framework.Simplify;

public import hunt.framework.application.Application : app;
public import hunt.framework.application.ApplicationConfig : configManager, ApplicationConfig;
public import hunt.util.DateTime : time, date;
public import hunt.framework.Init;
public import hunt.storage.redis : redis;

import std.string;

ApplicationConfig config()
{
    return configManager().config();
}

string url(string mca) {
    return url(mca, null);
}

string url(string mca, string[string] params, string group) {
    return app().router().createUrl(mca, params, group);
}

string url(string mca, string[string] params) {
    // admin:user.user.view
    string[] items = mca.split(":");
    string group = "";
    string pathItem = "";
    if (items.length == 1) {
        group = "";
        pathItem = mca;
    } else if (items.length == 2) {
        group = items[0];
        pathItem = items[1];
    } else {
        throw new Exception("Bad format for mca");
    }

    return app().router().createUrl(pathItem, params, group);
}
