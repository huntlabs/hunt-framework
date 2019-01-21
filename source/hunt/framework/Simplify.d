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
// public import hunt.framework.http.cookie.CookieManager : cookie;

public import hunt.util.DateTime;

string createUrl(string mca)
{
    return createUrl(mca, null);
}

string createUrl(string mca, string[string] params)
{
    // admin:user.user.view
    group = null;
    
    return app().router().createUrl(mca, params, group);
}
