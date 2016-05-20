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
module hunt.web.http.request;

import collie.codec.http;

import hunt.web.http.webfrom;

class Request
{
    this(HTTPRequest req)
    {
        assert(req);
        _req = req;
    }

    @property WebForm postForm()
    {
        if (_form is null)
            _form = new WebForm(_req);
        return _form;
    }

    alias httpRequest this;

    @property httpRequest()
    {
        return _req;
    }

    @property mate()
    {
        return _mate;
    }

    string getMate(string key)
    {
        return _mate.get(key, "");
    }

    void addMate(string key, string value)
    {
        _mate[key] = value;
    }

    @property ref string[string] materef() {return _mate;}
private:
    HTTPRequest _req;
    WebForm _form = null;
    string[string] _mate;
}
