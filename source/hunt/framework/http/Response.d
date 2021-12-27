/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.http.Response;

import hunt.framework.http.HttpErrorResponseHandler;
import hunt.http.HttpStatus;
import hunt.http.server;
import hunt.io.ByteBuffer;
import hunt.serialization.JsonSerializer;
import hunt.logging;

import std.conv;
import std.json;
import std.range;
import std.traits;

/**
 * 
 */
class Response {
    protected HttpServerResponse _response;
    private bool _bodySet = false;

    this() {
        _response = new HttpServerResponse();
    }

    this(string content) {
        HttpBody hb = HttpBody.create(content);
        this(hb);
    }

    this(HttpBody bodyContent) {
        this(new HttpServerResponse(bodyContent));
    }

    this(HttpServerResponse response) {
        this._response = response;
    }

    HttpServerResponse httpResponse() {
        return _response;
    }

    HttpFields getFields() {
        return _response.getFields();
    }

    Response header(T)(string header, T value) {
        getFields().put(header, value);
        return this;
    }

    Response header(T)(HttpHeader header, T value) {
        getFields().put(header, value);
        return this;
    }

    Response headers(T = string)(T[string] headers) {
        foreach (string k, T v; headers)
            getFields().add(k, v);
        return this;
    }

    Response setRestContent(T)(T content) {
        if(_bodySet) {
            version(HUNT_DEBUG) warning("The body is set again.");
        }

        string contentType = MimeType.APPLICATION_JSON_VALUE;

        static if(is(T : ByteBuffer)) {
            HttpBody hb = HttpBody.create(contentType, content);
        } else static if(isSomeString!T) {
            HttpBody hb = HttpBody.create(contentType, content);
        } else {
            JSONValue js = JsonSerializer.toJson(content);
            string c = js.toString();
            HttpBody hb = HttpBody.create(contentType, c);
        }
        _response.setBody(hb);
        _bodySet = true;
        return this;        
    }

    /**
     * Sets the response content.
     *
     * @return this
     */
    Response setContent(T)(T content, string contentType = MimeType.TEXT_HTML_VALUE) {
        if(_bodySet) {
            version(HUNT_DEBUG) warning("The body is set again.");
        }

        static if(is(T : ByteBuffer)) {
            HttpBody hb = HttpBody.create(contentType, content);
        } else static if(isSomeString!T) {
            HttpBody hb = HttpBody.create(contentType, content);
        } else static if(is(T : K[], K) && is(Unqual!K == ubyte)) {
            HttpBody hb = HttpBody.create(contentType, content);
        } else {
            string c = content.to!string();
            HttpBody hb = HttpBody.create(contentType, c);
        }
        _response.setBody(hb);
        _bodySet = true;
        return this;
    }

    Response setHtmlContent(string content) {
        setContent(content, MimeType.TEXT_HTML_UTF_8.toString());
        return this;
    }


    ///set http status code eg. 404 200
    Response setStatus(int status) {
        _response.setStatus(status);
        return this;
    }

    int status() @property {
        return _response.getStatus();
    }


    Response setReason(string reason) {
        _response.setReason(reason);
        return this;
    }

    ///download file 
    Response download(string filename, ubyte[] file, string content_type = "binary/octet-stream") {
        header(HttpHeader.CONTENT_TYPE, content_type);
        header(HttpHeader.CONTENT_DISPOSITION,
                "attachment; filename=" ~ filename ~ "; size=" ~ (file.length.to!string));
        setContent(file);

        return this;
    }

    /**
     * Add a cookie to the response.
     *
     * @param  Cookie cookie
     * @return this
     */
    Response withCookie(Cookie cookie) {
        _response.withCookie(cookie);
        return this;
    }

//     /// the session store implementation.
//     @property HttpSession session() {
//         return _request.session();
//     }

//     /// ditto
//     // @property void session(HttpSession se) {
//     //     _session = se;
//     // }


//     // void redirect(string url, bool is301 = false)
//     // {
//     //     if (_isDone)
//     //         return;

//     //     setStatus((is301 ? 301 : 302));
//     //     setHeader(HttpHeader.LOCATION, url);

//     //     connectionClose();
//     //     done();
//     // }

    void do404(string body_ = "", string contentype = "text/html;charset=UTF-8") {
        doError(404, body_, contentype);
    }

    void do403(string body_ = "", string contentype = "text/html;charset=UTF-8") {
        doError(403, body_, contentype);
    }

    void doError(ushort code, string body_ = "", string contentype = "text/html;charset=UTF-8") {

        setStatus(code);
        getFields().put(HttpHeader.CONTENT_TYPE, contentype);
        setContent(errorPageHtml(code, body_));
    }

    void doError(ushort code, Throwable exception, string contentype = "text/html;charset=UTF-8") {

        setStatus(code);
        getFields().put(HttpHeader.CONTENT_TYPE, contentype);

        version(HUNT_DEBUG) {
            setContent(errorPageWithStack(code, "<pre>" ~ exception.toString() ~ "/<pre>"));
        } else {
            setContent(errorPageWithStack(code, exception.msg));
        }
    }    

    void setHttpError(ushort code) {
        this.setStatus(code);
        this.setContent(errorPageHtml(code));
    }

    
    alias setHeader = header;
    alias withHeaders = headers;
    alias withContent = setContent;
}
