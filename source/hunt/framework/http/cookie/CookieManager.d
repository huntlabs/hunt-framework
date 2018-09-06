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

module hunt.framework.http.cookie.CookieManager;

import hunt.framework.http.cookie.Cookie;
import hunt.framework.application.application;
import std.string;

class CookieManager
{
    private
    {
        string[string] _requestCookies;
        Cookie[string] _responseCookies;
    }

    this(string requestCookieString = null)
    {
        if (requestCookieString.length > 0)
            parseCookie(requestCookieString);
    }

    CookieManager set(string key, string value)
    {
        _responseCookies[key] = new Cookie(key, value,
                app().config.cookie.expires,
                app().config.cookie.path,
                app().config.cookie.domain,
                app().config.cookie.secure,
                app().config.cookie.httpOnly
            );

        return this;
    }

    string get(string key, string defaultValue = null)
    {
        return _requestCookies.get(key, defaultValue);
    }

    string[string] requestCookies()
    {
        return _requestCookies;
    }

    Cookie[string] responseCookies()
    {
        return _responseCookies;
    }
    
    private void parseCookie(string header)
    {
        /// if cookie string is not null
        if (header is null)
            return;

        string[] cookie_parts = header.split(";");

        foreach (idx, part; cookie_parts)
        {
            string[] keyvalue = part.split("=");

            if (keyvalue.length != 2) // WTF!?
                continue;

            string key = keyvalue[0].strip;

            if (key[0] == '$')
                continue;

            string quoted_value = keyvalue[1];

            string lkey = toLower(key);

            if (lkey in RESERVED_PARAMS)
            {
                // what??!
            }
            else
            {
                _requestCookies[key] = cookie_unquote(quoted_value);
            }
        }
    }
}

CookieManager cookie()
{
    import hunt.framework.http.request;
    return request().cookieManager();
}
