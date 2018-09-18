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

module hunt.framework.http.Response;

import std.conv;
import std.datetime;
import std.json;
import std.typecons;

import hunt.datetime;
import hunt.http.codec.http.model;
import hunt.http.codec.http.stream.HttpOutputStream;
import hunt.io.common;
import hunt.io.BufferedOutputStream;
import hunt.logging;
import hunt.util.common;
import hunt.util.exception;

import hunt.framework.http.Request;
import hunt.framework.utils.string;
import hunt.framework.versions;

enum PlainContentType = "text/plain;charset=utf-8";
enum HtmlContentType = "text/html;charset=utf-8";
enum JsonContentType = "application/json;charset=utf-8";
enum OctetStreamContentType = "binary/octet-stream";

/**
*/
class Response : Closeable {
    protected HttpResponse _response;
    protected Request _request;
    protected HttpOutputStream _output;
    protected HttpURI _uri;
    protected BufferedOutputStream _bufferedOutput;
    protected int _bufferSize = 8 * 1024;

    this(Request request, int bufferSize = 8 * 1024) {
        initialize(request, bufferSize);

        this._response.setStatus(HttpStatus.OK_200);
        this._response.setHttpVersion(HttpVersion.HTTP_1_1);

    }

    // this(HttpResponse response, HttpOutputStream output, HttpURI uri, int bufferSize = 8 * 1024) {
    //     this._output = output;
    //     this._response = response;
    //     this._uri = uri;
    //     this.bufferSize = bufferSize;
    // }

    this(Request request, string content, int status = HttpStatus.OK_200, int bufferSize = 8 * 1024) {
        this(request, cast(const(ubyte)[]) content, status, bufferSize);
    }

    this(Request request, const(ubyte)[] content, int status = HttpStatus.OK_200,
            int bufferSize = 8 * 1024) {
        initialize(request, bufferSize);
        this._response.setStatus(status);
        this._response.setHttpVersion(HttpVersion.HTTP_1_1);
        this.setContent(content);

    }

    HttpResponse httpResponse() {
        return _response;
    }

    void setRequest(Request request, bool isFore = false) {
        assert(request !is null);
        if (isFore)
            initialize(request);
        else if (_request is null)
            initialize(request);
    }

    private void initialize(Request request, int bufferSize = 8 * 1024) {
        this._request = request;
        this._response = request.getResponse();
        this._output = request.outputStream;
        this._uri = request.getURI();
        this._bufferSize = bufferSize;
        _isInitilized = true;
    }

    private bool _isInitilized = false;

    private void validateHandler() {
        if (_request is null)
            throw new Exception("The request handler is null!");
    }

    HttpFields getFields() {
        return _response.getFields();
    }

    Response setHeader(T = string)(string header, T value) {
        getFields().put(header, value);
        return this;
    }

    Response setHeader(T)(HttpHeader header, T value) {
        getFields().put(header, value);
        return this;
    }

    Response header(T)(string header, T value) {
        getFields().put(header, value);
        return this;
    }

    Response header(T)(HttpHeader header, T value) {
        getFields().put(header, value);
        return this;
    }

    Response addHeader(T = string)(string header, T value) {
        getFields().add(header, value);
        return this;
    }

    Response addHeader(T = string)(HttpHeader header, T value) {
        getFields().add(header, value);
        return this;
    }

    Response withHeaders(T = string)(T[string] headers) {
        foreach (string k, T v; headers)
            getFields().add(k, v);
        return this;
    }

    /**
     * Sets the response content.
     *
     * @return this
     */
    Response setContent(string content) {
        return setContent(cast(const(ubyte)[]) content);
    }

    // ditto
    Response setContent(const(ubyte)[] content) {
        getOutputStream().write(cast(byte[]) content, 0, cast(int) content.length);

        return this;
    }

    void writeContent(string content) {
        writeContent(cast(const(ubyte)[]) content);
    }

    void writeContent(const(ubyte)[] content) {
        getOutputStream().write(cast(byte[]) content, 0, cast(int) content.length);
    }

    /**
     * Get the content of the response.
     *
     * @return string
     */
    // T getContent(T = string)()
    // {
    //     return cast(T) _body.allData.data();
    // }

    /**
     * Get the original response content.
     *
     * @return mixed
     */
    // const(ubyte)[] getOriginalContent()
    // {
    //     return _body.allData.data();
    // }

    ///set http status code eg. 404 200
    Response setStatus(int status) {
        _response.setStatus(status);
        return this;
    }

    Response setReason(string reason) {
        _response.setReason(reason);
        return this;
    }

    ///download file 
    Response download(string filename, ubyte[] file, string content_type = "binary/octet-stream") {
        setHeader(HttpHeader.CONTENT_TYPE, content_type).setHeader(HttpHeader.CONTENT_DISPOSITION,
                "attachment; filename=" ~ filename ~ "; size=" ~ (file.length.to!string)).setContent(
                file);

        return this;
    }

    /**
     * Add a cookie to the response.
     *
     * @param  Cookie cookie
     * @return this
     */
    Response withCookie(Cookie cookie) {
        getFields().add(HttpHeader.SET_COOKIE, CookieGenerator.generateSetCookie(cookie));
        return this;
    }

    pragma(inline) final void done() {
        if (_isDone)
            return;
        ///set session
        if (request.hasSession() && request.session.isStarted()) {
            withCookie(new Cookie("hunt_session", request.session.getId(), 0,
                    "/", null, false, false));
        }
        // setCookieHeaders();
        setHeader("Date", date("Y-m-d H:i:s"));
        setHeader(HttpHeader.X_POWERED_BY, XPoweredBy);
        // sendWithEOM();
        try {
            this.close();
        }
        catch (IOException ex) {
            error(ex.toString());
        }
    }

    // void redirect(string url, bool is301 = false)
    // {
    //     if (_isDone)
    //         return;

    //     setStatus((is301 ? 301 : 302));
    //     setHeader(HttpHeader.LOCATION, url);

    //     connectionClose();
    //     done();
    // }

    void do404(string body_ = "", string contentype = "text/html;charset=UTF-8") {
        doError(404, body_, contentype);
    }

    void do403(string body_ = "", string contentype = "text/html;charset=UTF-8") {
        doError(403, body_, contentype);
    }

    void doError(ushort code, string body_ = "", string contentype = "text/html;charset=UTF-8") {
        if (_isDone)
            return;

        setStatus(code);
        getFields().put(HttpHeader.CONTENT_TYPE, contentype);
        setContent(errorPageHtml(code, body_));
        //       connectionClose();
        done();
    }

    void setHttpError(ushort code) {
        this.setStatus(code);
        this.setContent(errorPageHtml(code));
    }

    OutputStream getOutputStream() {
        if (_bufferedOutput is null) {
            _bufferedOutput = new BufferedOutputStream(_output, _bufferSize);
        }
        return _bufferedOutput;
    }

    bool isClosed() {
        return _isDone;
    }

    void close() {
        _isDone = true;
        if (_bufferedOutput !is null) {
            _bufferedOutput.close();
        }
        else {
            getOutputStream().close();
        }
    }

private:
    bool _isDone = false;
    // ResponseCookieEncoder _cookieEncoder;
}

// dfmt off
string errorPageHtml(int code , string _body = "")
{
    import std.conv : to;

    string text = code.to!string;
    text ~= " ";
    text ~= HttpStatus.getMessage(code);

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
