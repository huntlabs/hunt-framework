module hunt.framework.http.RedirectResponse;

import std.conv;
import std.datetime;
import std.json;

import hunt.http.codec.http.model.HttpHeader;
import hunt.logging;
import hunt.lang.exception;

import hunt.framework.utils.string;
import hunt.framework.versions;
import hunt.framework.http.Response;
import hunt.framework.http.Request;
import hunt.framework.http.session;
import hunt.framework.exception;

/**
 * RedirectResponse represents an HTTP response doing a redirect.
 *
 */
class RedirectResponse : Response
{
    protected HttpSession _session;

    this(Request request, string targetUrl, bool use301 = false)
    {
        super(request);

        setStatus((use301 ? 301 : 302));
        setHeader(HttpHeader.LOCATION, targetUrl);
        // connectionClose();
    }

    /// the session store implementation.
    @property HttpSession session()
    {
        return _session;
    }

    /// ditto
    @property void session(HttpSession se)
    {
        _session = se;
    }

    /**
     * Flash a piece of data to the session.
     *
     * @param  string|array  key
     * @param  mixed  value
     * @return RedirectResponse
     */
    RedirectResponse withSession(string key, string value)
    {
        // _session.flash(key, value);
        implementationMissing(false);
        return this;
    }

    /// ditto
    RedirectResponse withSession(string[string] sessions)
    {
        implementationMissing(false);
        // foreach (string key, string value; sessions)
        // {
        //     _session.flash(key, value);
        // }
        return this;
    }
    
    /**
     * Flash an array of input to the session.
     *
     * @param  array  input
     * @return this
     */
    RedirectResponse withInput(string[string] input = null)
    {
        // _session.flashInput(input is null ? _request.input() : input);
        implementationMissing(false);

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
