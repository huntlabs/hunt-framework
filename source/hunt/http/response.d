/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.http.response;

import std.datetime;
import std.json;

import collie.codec.http.headers.httpcommonheaders;
import collie.codec.http.server.responsehandler;
import collie.codec.http.server.responsebuilder;
import collie.codec.http.httpmessage;
import kiss.logger;
import hunt.http.cookie;
import hunt.utils.string;
import hunt.versions;

enum XPoweredBy = "Hunt " ~ HUNT_VERSION;

final class Response : ResponseBuilder
{
    this(ResponseHandler resp)
    {
        super(resp);
        setHttpStatusCode(200);
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
    auto setHttpStatusCode(ushort code)
    {
        status(code,HTTPMessage.statusText(code));

        return this;
    }

    ///return json value
    auto json(JSONValue js)
    {
        json(js.toString());

        return this;
    }
    ///render json string value
    auto json(string jsonString)
    {
        setHeader(HTTPHeaderCode.CONTENT_TYPE, "application/json;charset=utf-8").setContext(jsonString);

        return this;
    }

    ///render html string 
    auto html(string htmlString, string content_type = "text/html;charset=utf-8")
    {
        setHeader(HTTPHeaderCode.CONTENT_TYPE, content_type).setContext(htmlString);

        return this;
    }

    ///render plain text string 
    auto plain(string textString, string content_type = "text/plain;charset=utf-8")
    {
        setHeader(HTTPHeaderCode.CONTENT_TYPE, content_type).setContext(textString);

        return this;
    }

    ///download file 
    auto download(string filename,ubyte[] file, string content_type = "binary/octet-stream")
    {
		import std.conv;
		setHeader(HTTPHeaderCode.CONTENT_TYPE, content_type)
		.setHeader(HTTPHeaderCode.CONTENT_DISPOSITION,
				"attachment; filename="~filename~"; size="~(file.length.to!string))
		.setContext(file);

        return this;
    }

    /**
     * set Cookie
     */
    auto setCookie(string name, string value, int expires = 0, string path = "/", string domain = null)
    {

        import std.typecons;
        auto cookie = scoped!Cookie(name, value, [
                "path": path,
                "domain": domain
            ]);

        if (expires != 0)
        {
            import std.conv; 
            cookie.params["max-age"] = (expires < 0) ? "0" : to!string(expires);
        }
        
        setHeader(HTTPHeaderCode.SET_COOKIE, cookie.output(""));

        return this;
    }

	/**
	 * delete Cookie
	 */
	auto delCookie(string name)
	{
		setCookie(name,null,0);
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

    void do404(string body_ = "",string contentype = "text/html;charset=UTF-8")
    {
		doError(404 , body_ , contentype);
    }

	void do403(string body_ = "",string contentype = "text/html;charset=UTF-8")
	{
		doError(403 , body_ , contentype);
	}

	void doError(ushort code ,  string body_ = "",string contentype = "text/html;charset=UTF-8")
	{
		if(_isDone) return;
		
		setHttpStatusCode(code);
		header(HTTPHeaderCode.CONTENT_TYPE, contentype);
		setContext(errorPageHtml(code , body_));
		connectionClose();
		done();
	}

    void setHttpError(ushort code)
    {
        this.setHttpStatusCode(code);
        this.setContext(errorPageHtml(code));
    }

package(hunt.http):
    void clear()
    {
        setResponseHandler(null);
    }
private:
    bool _isDone = false;
}

import hunt.http.code;

string errorPageHtml(int code , string _body = "")
{
    import std.conv : to;

    string text = code.to!string;
    text ~= " ";
    text ~= HTTPCodeText(code);

    string html = `<!doctype html>
<html lang="en">
    <meta charset="utf-8">
    <title>`;

    html ~= text;
    html ~= `</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>

        * {
            line-height: 3;
            margin: 0;
        }

        html {
            color: #888;
            display: table;
            font-family: sans-serif;
            height: 100%;
            text-align: center;
            width: 100%;
        }

        body {
            display: table-cell;
            vertical-align: middle;
            margin: 2em auto;
        }

        h1 {
            color: #555;
            font-size: 2em;
            font-weight: 400;
        }

        p {
            margin: 0 auto;
            width: 90%;
        }

    </style>
</head>
<body>
    <h1>`;
    html ~= text;
    html ~= `</h1>
    <p>Sorry!! Unable to complete your request :(</p>
	`;
	if(_body.length > 0)
		html ~= "<p>" ~ _body ~ "</p>";
html ~= `
</body>
</html>
`;

    return html;
}
