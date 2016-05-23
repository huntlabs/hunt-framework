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
module hunt.web.http.response;

import std.datetime;
import std.json;

import collie.codec.http;

import hunt.web.http.cookie;
import hunt.web.http.webfrom;
import hunt.utils.string;

class Response
{
    this(HTTPResponse resp)
    {
        _rep = resp;
    }

    void setHeader(T = string)(string key, T value)
    {
        _rep.Header.setHeaderValue(key, value);
    }

    void write(ubyte[] data)
    {
        _rep.Body.write(data);
    }

    void setContext(string str)
    {
        _rep.Body.write(cast(ubyte[]) str);
    }

    void setContext(ubyte[] data)
    {
        _rep.Body.write(data);
    }

	///set http status code eg. 404 200
    void setHttpStatusCode(int code)
    {
        _rep.Header.statusCode(code);
    }

	///return json value
	void writeJson(JSONValue json)
	{
		setHeader("Content-Type", "application/json;charset=UTF-8");
		setContext(json.toString());
	}
    /**
	* 设置Session Cookie
	*/
    void setCookie(string name, string value, int expires, string path = "/", string domain = null)
    {
        auto cookie = new Cookie(name, value, ["path" : path, "domain" : domain,
            "expires" : printDate(cast(DateTime) Clock.currTime(UTC()) + dur!"seconds"(expires))]);
        ///TODO set into base
        this.setHeader("set-cookie", cookie.output(""));
    }


    alias httpResponse this;

    @property httpResponse()
    {
        return _rep;
    }

private:
    HTTPResponse _rep;
}
