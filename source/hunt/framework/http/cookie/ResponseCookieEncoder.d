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

module hunt.framework.http.cookie.ResponseCookieEncoder;

import hunt.framework.http.cookie.Cookie;

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

    ResponseCookieEncoder add(string k, string v = null)
    {
        _result ~= ((_result is null) ? "" : "; ") ~ k ~ (( v is null) ? "" : ("=" ~ cookie_quote(v)));
	    return this;
    }

    string encode(Cookie cookie)
    {
        import std.conv : to;
	    import kiss.datetime;

        add(cookie.name(), cookie.value());

	    if (cookie.domain() !is null) add(CookieHeaders.DOMAIN, cookie.domain());

	    add(CookieHeaders.PATH, cookie.path());

        if (cookie.expires())
        {   
            add(CookieHeaders.EXPIRES, std.datetime.SysTime.fromUnixTime(time() + cookie.expires()).toString());
        }
        
        if (cookie.secure())
        {
            add(CookieHeaders.SECURE);
        }

        if (cookie.httpOnly())
        {
            add(CookieHeaders.HTTPONLY);
        }

        scope(exit)
        {
            _result = null;
        }

         return _result;
    }
}
