/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Website: www.huntframework.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.simplify;

public import hunt.framework.application.application : app;
// public import hunt.framework.http.cookie.CookieManager : cookie;

public import hunt.datetime;

string createUrl(string mca, string[string] params = null, string group = null)
{
    return app().router().createUrl(mca, params, group);
}
