module hunt.framework.http.RedirectResponse;

import hunt.framework.http.Response;

import hunt.Exceptions;
import hunt.http.server;
import hunt.logging.ConsoleLogger;


import std.conv;
import std.datetime;
import std.json;


// import hunt.framework.util.String;
// import hunt.framework.Version;
// import hunt.framework.http.Response;
import hunt.framework.http.Request;
// import hunt.framework.http.session;
// import hunt.framework.Exceptions;

/**
 * RedirectResponse represents an HTTP response doing a redirect.
 *
 */
class RedirectResponse : Response {

    private Request _request;

    // this(string targetUrl, bool use301 = false) {
    //     setStatus((use301 ? 301 : 302));
    //     header(HttpHeader.LOCATION, targetUrl);
    //     // connectionClose();
    // }

    this(Request request, string targetUrl, bool use301 = false) {
        // super(request());
        super();
        _request = request;

        setStatus((use301 ? 301 : 302));
        header(HttpHeader.LOCATION, targetUrl);
        // connectionClose();
    }

    private HttpSession session() {
        return _request.session();
    }

    /**
     * Flash a piece of data to the session.
     *
     * @param  string|array  key
     * @param  mixed  value
     * @return RedirectResponse
     */
    RedirectResponse withSession(string key, string value) {
        session.flash(key, value);
        return this;
    }

    /// ditto
    RedirectResponse withSession(string[string] sessions) {
        foreach (string key, string value; sessions) {
            session.flash(key, value);
        }
        return this;
    }

    /**
     * Flash an array of input to the session.
     *
     * @param  array  input
     * @return this
     */
    RedirectResponse withInput(string[string] input = null) {
        session.flashInput(input is null ? _request.input() : input);
        return this;
    }

    /**
     * Remove all uploaded files form the given input array.
     *
     * @param  array  input
     * @return array
     */
    // protected string[string] removeFilesFromInput(string[string] input)
    // {
    //     throw new NotImplementedException("removeFilesFromInput");
    // }

    /**
     * Flash an array of input to the session.
     *
     * @return this
     */
    // RedirectResponse onlyInput(string[] keys...)
    // {
    //     return withInput(_request.only(keys));
    // }

    /**
     * Flash an array of input to the session.
     *
     * @return this
     */
    // RedirectResponse exceptInput(string[] keys...)
    // {
    //     return withInput(_request.except(keys));
    // }

    /**
     * Get the original response content.
     *
     * @return null
     */
    // override const(ubyte)[] getOriginalContent()
    // {
    //     return null;
    // }
}
