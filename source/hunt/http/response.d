/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */
module hunt.http.response;

import std.datetime;
import std.json;

import collie.codec.http;

import hunt.http.cookie;
import hunt.http.webfrom;
import hunt.utils.string;

import hunt.versions;

enum XPoweredBy = "Hunt " ~ HUNT_VERSION;

class Response
{
    this(HTTPResponse resp)
    {
        _rep = resp;
    }

    auto setHeader(T = string)(string key, T value)
    {
        _rep.Header.setHeaderValue(key, value);
        return this;
    }

    auto write(ubyte[] data)
    {
        _rep.Body.write(data);
        return this;
    }

    auto setContext(string str)
    {
        _rep.Body.write(cast(ubyte[]) str);
        return this;
    }

    auto setContext(ubyte[] data)
    {
        _rep.Body.write(data);
        return this;
    }

    ///set http status code eg. 404 200
    auto setHttpStatusCode(int code)
    {
        _rep.Header.statusCode(code);
        return this;
    }

    ///return json value
    auto json(JSONValue json)
    {
        setContext(json.toString()).setHeader("Content-Type", "application/json;charset=UTF-8");
        return this;
    }
    ///render json string value
    auto json(string jsonString)
    {
        setContext(jsonString).setHeader("Content-Type", "application/json;charset=UTF-8");
        return this;
    }
    ///render html string 
    auto html(string htmlString, string content_type = "text/html;charset=UTF-8")
    {
        setContext(htmlString).setHeader("content-type", content_type);
        return this;
    }
    ///render plain text string 
    auto plain(string textString, string content_type = "text/plain;charset=UTF-8")
    {
        setContext(textString).setHeader("content-type", content_type);
        return this;
    }

    /**
	* 设置Session Cookie
	*/
    auto setCookie(string name, string value, int expires, string path = "/", string domain = null)
    {
        import std.typecons;

        auto cookie = scoped!Cookie(name, value, ["path" : path, "domain"
                : domain, "expires"
                : printDate(cast(DateTime) Clock.currTime(UTC()) + dur!"seconds"(expires))]); //栈中优化
        this.setHeader("set-cookie", cookie.output(""));
        return this;
    }

    pragma(inline, true) final @property Header()
    {
        return _rep.Header();
    }

    pragma(inline, true) final @property Body()
    {
        return _rep.Body();
    }

    final bool append(ubyte[] data)
    {
        return _rep.append(data);
    }

    pragma(inline) final bool done()
    {
        setHeader("X-Powered-By", XPoweredBy);
        return _rep.done(null, 0);
    }

    pragma(inline) final bool done(string file)
    {
        setHeader("X-Powered-By", XPoweredBy);
        return _rep.done(file, 0);
    }

    pragma(inline) final bool done(string file, ulong begin)
    {
        setHeader("X-Powered-By", XPoweredBy);
        return _rep.done(file, begin);
    }

    pragma(inline) final void close()
    {
        _rep.close();
    }

    void redirect(string url, bool is301 = false)
    {

        _rep.Header.statusCode((is301 ? 301 : 302));
        _rep.Header.setHeaderValue("Location", url);
        _rep.done();
    }

private:
    HTTPResponse _rep;
}
