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

module hunt.http.cookie.ResponseCookieEncoder;

import hunt.http.cookie.Cookie;

enum CookieHeaders: string
{
    PATH = "Path",
    MAXAGE = "Max-Age",
    DOMAIN = "Domain",
    EXPIRES = "Expires",
    SECURE = "Secure",
    HTTPONLY = "HTTPOnly",
    SAMESITE = "SameSite"
}

class ResponseCookieEncoder
{
    private string _result;

    ResponseCookieEncoder add(string k, string v)
    {
        _result = ((_result is null) ? "" : "; ") ~ k ~ "=" ~ cookie_quote(v);
        return this;
    }

    string encode(Cookie cookie)
    {
        import std.conv : to;

        add(cookie.name(), cookie.value());
        add(CookieHeaders.DOMAIN, cookie.domain());
        add(CookieHeaders.PATH, cookie.path());
        add(CookieHeaders.EXPIRES, cookie.expires().to!string);
        add(CookieHeaders.SECURE, cookie.secure().to!string);
        add(CookieHeaders.HTTPONLY, cookie.httpOnly().to!string);

        scope(exit)
        {
            _result = null;
        }

        return _result;
    }
}
