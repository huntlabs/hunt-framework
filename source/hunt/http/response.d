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
        import std.typecons;
        auto cookie = scoped!Cookie(name, value, ["path" : path, "domain" : domain,
            "expires" : printDate(cast(DateTime) Clock.currTime(UTC()) + dur!"seconds"(expires))]); //栈中优化
        ///TODO set into base
        this.setHeader("set-cookie", cookie.output(""));
    }


	pragma(inline,true)
	final @property Header()
	{
		return _rep.Header();
	}
	
	pragma(inline,true)
	final @property Body()
	{
		return _rep.Body();
	}
	
	final bool append(ubyte[] data)
	{
		return _rep.append(data);
	}
	
	pragma(inline)
	final bool done()
	{
		setHeader("XPoweredBy",XPoweredBy);
		return _rep.done(null, 0);
	}
	
	pragma(inline)
	final bool done(string file)
	{
		setHeader("XPoweredBy",XPoweredBy);
		return _rep.done(file, 0);
	}

	pragma(inline)
	final bool done(string file, ulong begin)
	{
		setHeader("XPoweredBy",XPoweredBy);
		return _rep.done(file, begin);
	}
	
	pragma(inline)
	final void close()
	{
		_rep.close();
	}
    
    void redirect(string url, bool is301 = false)
    {
        
		_rep.Header.statusCode((is301 ? 301 : 302));
		_rep.Header.setHeaderValue("Location",url);
		_rep.done();
    }

private:
    HTTPResponse _rep;
}
