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

import collie.codec.http.headers.httpcommonheaders;
import collie.codec.http.server.responsehandler;
import collie.codec.http.server.responsebuilder;
import collie.codec.http.httpmessage;

import hunt.http.cookie;
import hunt.utils.string;

import hunt.versions;

enum XPoweredBy = "Hunt " ~ HUNT_VERSION;

final class Response : ResponseBuilder
{
    this(ResponseHandler resp)
    {
		super(resp);
    }

    auto setHeader(T = string)(string key, T value)
    {
		header!T(key,value);
        return this;
    }

	auto setHeader(T = string)(HTTPHeaderCode key, T value)
	{
		header!T(key,value);
		return this;
	}

    auto setContext(string str)
    {
		setBody(cast(ubyte[]) str);
        return this;
    }

    auto setContext(ubyte[] data)
    {
		setBody(data);
        return this;
    }

    ///set http status code eg. 404 200
    auto setHttpStatusCode(int code)
    {
		promise(code,HTTPMessage.statusText(code));
        return this;
    }

    ///return json value
    auto json(JSONValue json)
    {
		json(json.toString());
        return this;
    }
    ///render json string value
    auto json(string jsonString)
    {
		setHeader(HTTPHeaderCode.CONTENT_TYPE, "application/json;charset=UTF-8").setContext(jsonString);
        return this;
    }
    ///render html string 
    auto html(string htmlString, string content_type = "text/html;charset=UTF-8")
    {
		setHeader(HTTPHeaderCode.CONTENT_TYPE, content_type).setContext(htmlString);
        return this;
    }
    ///render plain text string 
    auto plain(string textString, string content_type = "text/plain;charset=UTF-8")
    {
		setHeader(HTTPHeaderCode.CONTENT_TYPE, content_type).setContext(textString);
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
        setHeader(HTTPHeaderCode.SET_COOKIE, cookie.output(""));
        return this;
    }

    pragma(inline) final void done()
    {
		if(_isDone) return;
		_isDone = true;
		setHeader(HTTPHeaderCode.X_POWERED_BY, XPoweredBy);
        sendWithEOM();
    }

    void redirect(string url, bool is301 = false)
    {
		if(_isDone) return;
		setHttpStatusCode((is301 ? 301 : 302));
		setHeader(HTTPHeaderCode.LOCATION, url);
		connectionClose();
		done();
    }

	void do404(string body_ = "",string contentype = "text/plain;charset=UTF-8")
	{
		if(_isDone) return;
		setHttpStatusCode(404);
		header(HTTPHeaderCode.CONTENT_TYPE,"text/plain;charset=UTF-8");
		if(body_.length > 0)
			setContext(body_);
		connectionClose();
		done();
	}

package(hunt.http):
	void clear(){
		setResponseHandler(null);
	}
private:
	bool _isDone = false;
}
