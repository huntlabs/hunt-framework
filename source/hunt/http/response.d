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

module hunt.http.response;

import std.conv;
import std.datetime;
import std.json;
import std.typecons;

import collie.codec.http.headers.httpcommonheaders;
import collie.codec.http.server.responsehandler;
import collie.codec.http.server.responsebuilder;
import collie.codec.http.httpmessage;

import kiss.logger;
import hunt.http.cookie;
import hunt.utils.string;
import hunt.versions;

enum PlainContentType = "text/plain;charset=utf-8";
enum HtmlContentType = "text/html;charset=utf-8";
enum JsonContentType = "application/json;charset=utf-8";
enum OctetStreamContentType = "binary/octet-stream";


/**
*/
class Response : ResponseBuilder
{
    this()
    {
        super();
    }

    this(string content, int status = HttpStatusCodes.OK, string[string] headers = null )
    {
        this(cast(const(ubyte)[])content, status, headers);
    }

    this(in ubyte[] content, int status = HttpStatusCodes.OK, string[string] headers = null )
    {
        super(null);
        if(headers !is null)
            this.withHeaders(headers);
        setStatus(status);
        this.setContent(content);
    }

    this(ResponseHandler handler)
    {
        super(handler);
        setStatus(200);
    }

    Response setHeader(T = string)(string key, T value)
    {
        header!T(key, value);

        return this;
    }

    Response setHeader(T = string)(HTTPHeaderCode key, T value)
    {
        header!T(key, value);

        return this;
    }

    Response addHeader(T = string)(HTTPHeaderCode key, T value)
    {
        _httpMessage.addHeader(key, value);
        return this;
    }

    /**
     * Sets the response content.
     *
     * @return this
     */
    Response setContent(string content)
    {
        return setContent(cast(ubyte[]) content);
    }

    // ditto
    Response setContent(in ubyte[] content)
    {
        setBody(cast(ubyte[]) content);

        return this;
    }

    /**
     * Get the content of the response.
     *
     * @return string
     */
    T getContent(T = string)()
    {
        return cast(T) _body.allData.data();
    }

    /**
     * Get the original response content.
     *
     * @return mixed
     */
    const(ubyte)[] getOriginalContent()
    {
        return _body.allData.data();
    }

    // ///set http status code eg. 404 200
    Response setStatus(int code)
    {
        status(cast(ushort)code, HttpMessage.statusText(code));
        return this;
    }

    ///download file 
    Response download(string filename, ubyte[] file, string content_type = "binary/octet-stream")
    {
        setHeader(HTTPHeaderCode.CONTENT_TYPE, content_type).setHeader(HTTPHeaderCode.CONTENT_DISPOSITION,
                "attachment; filename=" ~ filename ~ "; size=" ~ (file.length.to!string)).setContent(
                file);

        return this;
    }

    /**
     * set Cookie
     */
    Response setCookie(string name, string value, int expires = 0,
            string path = "/", string domain = null)
    {
        auto cookie = scoped!Cookie(name, value, ["path" : path, "domain" : domain]);

        if (expires != 0)
        {
            import std.conv;
            cookie.params["max-age"] = (expires < 0) ? "0" : to!string(expires);
        }

        addHeader(HTTPHeaderCode.SET_COOKIE, cookie.output(""));

        return this;
    }

    /**
	 * delete Cookie
	 */
    Response delCookie(string name)
    {
        setCookie(name, null, 0);
        return this;
    }

    /**
     * Add a cookie to the response.
     *
     * @param  Cookie cookie
     * @return this
     */
    Response cookie(Cookie cookie)
    {
        setHeader(HTTPHeaderCode.SET_COOKIE, cookie.output(""));
        return this;
    }

    /// ditto
    Response cookie(string name, string value, int expires = 0,
            string path = "/", string domain = null)
    {
        setCookie(name, value, expires, path, domain);
        return this;
    }


    pragma(inline) final void done()
    {
        if (_isDone)
            return;

        _isDone = true;
        setHeader(HTTPHeaderCode.X_POWERED_BY, XPoweredBy);
        sendWithEOM();
    }

    // void redirect(string url, bool is301 = false)
    // {
    //     if (_isDone)
    //         return;

    //     setStatus((is301 ? 301 : 302));
    //     setHeader(HTTPHeaderCode.LOCATION, url);

    //     connectionClose();
    //     done();
    // }


    void do404(string body_ = "", string contentype = "text/html;charset=UTF-8")
    {
        doError(404, body_, contentype);
    }

    void do403(string body_ = "", string contentype = "text/html;charset=UTF-8")
    {
        doError(403, body_, contentype);
    }

    void doError(ushort code, string body_ = "", string contentype = "text/html;charset=UTF-8")
    {
        if (_isDone)
            return;

        setStatus(code);
        header(HTTPHeaderCode.CONTENT_TYPE, contentype);
        setContent(errorPageHtml(code, body_));
        connectionClose();
        done();
    }

    void setHttpError(ushort code)
    {
        this.setStatus(code);
        this.setContent(errorPageHtml(code));
    }


private:
    bool _isDone = false;
}

// dfmt off
string errorPageHtml(int code , string _body = "")
{
    import std.conv : to;

    string text = code.to!string;
    text ~= " ";
    text ~= HttpMessage.statusText(code);

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

// dfmt on
