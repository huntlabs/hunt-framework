module hunt.http.response;

import std.datetime;

import collie.codec.http;

import hunt.http.cookie;
import hunt.http.webfrom;
import hunt.utils.string;

class Response
{
    this(HTTPResponse resp)
    {
        _rep = resp;
    }

    void setHeader(T)(string key, T value)
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

    void setHttpStatusCode(int code)
    {
        _rep.Header.statusCode(code);
    }

    /**
	* 设置Session Cookie
	*/
    void setCookie(string name, string value, int expires, string path = "/", string domain = null)
    {
        auto cookie = new Cookie(name, value, ["path" : path, "domain" : domain,
            "expires" : printDate(cast(DateTime) Clock.currTime(UTC()) + dur!"seconds"(expires))]);
        ///TODO set into base
        //_rep.setCookie(cookie.output);
    }

    alias httpResponse this;

    @property httpResponse()
    {
        return _rep;
    }

private:
    HTTPResponse _rep;
}
