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

module hunt.framework.http.Request;

import hunt.framework.auth;
import hunt.framework.file.UploadedFile;
import hunt.framework.http.session.SessionStorage;
import hunt.framework.Init;
import hunt.framework.provider.ServiceProvider;
import hunt.framework.routing;

import hunt.http.AuthenticationScheme;
import hunt.http.Cookie;
import hunt.http.HttpMethod;
import hunt.http.HttpHeader;
import hunt.http.MultipartForm;
import hunt.http.server.HttpServerRequest;
import hunt.http.server.HttpSession;
import hunt.logging;
import hunt.serialization.JsonSerializer;

import std.algorithm;
import std.array : split;
import std.base64;
import std.json;
import std.format;
import std.range;
import std.socket;

import core.time;


enum BasicTokenHeader = AuthenticationScheme.Basic ~ " ";
enum BearerTokenHeader = AuthenticationScheme.Bearer ~ " ";

/**
 * 
 */
class Request {

    private HttpSession _session;
    private SessionStorage _sessionStorage;
    private bool _isMultipart = false;
    private bool _isXFormUrlencoded = false;
    private UploadedFile[] _convertedAllFiles;
    private UploadedFile[][string] _convertedMultiFiles;
    private string _routeGroup = DEFAULT_ROUTE_GROUP;
    private string _actionId = "";
    private Auth _auth;
    private string _guardName = DEFAULT_GURAD_NAME;
    private MonoTime _monoCreated;
    private bool _isRestful = false;

    HttpServerRequest _request;
    alias _request this;

    this(HttpServerRequest request, Address remoteAddress, RouterContex routeContext=null) {
        _request = request;
        if(routeContext !is null) {
            ActionRouteItem routeItem = cast(ActionRouteItem)routeContext.routeItem;
            if(routeItem !is null)
                _actionId = routeItem.actionId;
            _routeGroup = routeContext.routeGroup.name;
            _guardName = routeContext.routeGroup.guardName;
        }
        _monoCreated = MonoTime.currTime;
        _sessionStorage = serviceContainer().resolve!SessionStorage();
        _remoteAddr = remoteAddress;

        .request(this); // Binding this request to the current thread.
    }

    Auth auth() {
        if(_auth is null) {
            _auth = new Auth(this);
        }
        return _auth;
    }

    bool isRestful() {
        return _isRestful;
    }

    void isRestful(bool value) {
        _isRestful = value;
    }
    

    /**
     * Determine if the uploaded data contains a file.
     *
     * @param  string  key
     * @return bool
     */
    bool hasFile(string key) {
        if (!isMultipartForm()) {
            return false;
        } else {
            checkUploadedFiles();

            if (_convertedMultiFiles is null || _convertedMultiFiles.get(key, null) is null) {
                return false;
            }
            return true;
        }
    }

    private void checkUploadedFiles() {
        if (!_convertedAllFiles.empty()) 
            return;

        foreach (Part part; _request.getParts()) {
            MultipartForm multipart = cast(MultipartForm) part;

            version (HUNT_HTTP_DEBUG) {
                string content = cast(string)multipart.getBytes();
                if(content.length > 128) {
                    content = content[0..128] ~ "...";
                }

                tracef("File: key=%s, fileName=%s, actualFile=%s, ContentType=%s, content=%s",
                        multipart.getName(), multipart.getSubmittedFileName(),
                        multipart.getFile(), multipart.getContentType(),
                        content); 
            }

            string contentType = multipart.getContentType();
            string submittedFileName = multipart.getSubmittedFileName();
            string key = multipart.getName();
            if (!submittedFileName.empty) {
                // TODO: for upload failed? What's the errorCode? use multipart.isWriteToFile?
                int errorCode = 0;
                multipart.flush();
                auto file = new UploadedFile(multipart.getFile(),
                        submittedFileName, contentType, errorCode);

                this._convertedMultiFiles[key] ~= file;
                this._convertedAllFiles ~= file;
            }
        }
    }


    /**
     * Retrieve a file from the request.
     *
     * @param  string  key
     * @param  mixed default
     * @return UploadedFile
     */
    UploadedFile file(string key)
    {
        if (this.hasFile(key))
        {
            return this._convertedMultiFiles[key][0];
        }

        return null;
    }

    UploadedFile[] files(string key)
    {
        if (this.hasFile(key))
        {
            return this._convertedMultiFiles[key];
        }

        return null;
    }

    @property int elapsed()    {
        Duration timeElapsed = MonoTime.currTime - _monoCreated;
        return cast(int)timeElapsed.total!"msecs";
    }

//     /**
//      * Custom parameters.
//      */
//     @property string[string] mate() {
//         return _mate;
//     }

//     string getMate(string key, string value = null) {
//         return _mate.get(key, value);
//     }

//     long size() @property
//     {
//         return _stringBody.length;
//     }

//     void addMate(string key, string value) {
//         _mate[key] = value;
//     }

//     @property string host() {
//         return header(HttpHeader.HOST);
//     }

//     string header(HttpHeader code) {
//         return getFields().get(code);
//     }

//     string header(string key) {
//         return getFields().get(key);
//     }

    bool headerExists(HttpHeader code) {
        return getFields().contains(code);
    }

    bool headerExists(string key) {
        return getFields().containsKey(key);
    }

//     // int headersForeach(scope int delegate(string key, string value) each)
//     // {
//     //     return getFields().opApply(each);
//     // }

//     // int headersForeach(scope int delegate(HttpHeader code, string key, string value) each)
//     // {
//     //     return getFields().opApply(each);
//     // }

//     // bool headerValueForeach(string name, scope bool delegate(string value) func)
//     // {
//     //     return getFields().forEachValueOfHeader(name, func);
//     // }

//     // bool headerValueForeach(HttpHeader code, scope bool delegate(string value) func)
//     // {
//     //     return getFields().forEachValueOfHeader(code, func);
//     // }

//     @property string referer() {
//         string rf = header("Referer");
//         string[] rfarr = split(rf, ", ");
//         if (rfarr.length) {
//             return rfarr[0];
//         }
//         return "";
//     }

    @property Address remoteAddr() {
        return _remoteAddr;
    }
    private Address _remoteAddr;

    @property string ip() {
        string s = this.header(HttpHeader.X_FORWARDED_FOR);
        if(s.empty) {
            s = this.header("Proxy-Client-IP");
        } else {
            auto arr = s.split(",");
            if(arr.length >= 0)
                s = arr[0];
        }

        if(s.empty) {
            s = this.header("WL-Proxy-Client-IP");
        }

        if(s.empty) {
            s = this.header("HTTP_CLIENT_IP");
        }

        if(s.empty) {
            s = this.header("HTTP_X_FORWARDED_FOR");
        } 

        if(s.empty) {
            Address ad = remoteAddr();
            s = ad.toAddrString();
        }

        return s;
    }    

    @property JSONValue json() {
        if (_json == JSONValue.init)
            _json = parseJSON(getBodyAsString());
        return _json;
    }
    private JSONValue _json;


    string getBodyAsString() {
        if (stringBody is null) {
            stringBody = _request.getStringBody();
        }
        return stringBody;
    }
    private string stringBody;

    private static bool isContained(string source, string[] keys) {
        foreach (string k; keys) {
            if (canFind(source, k))
                return true;
        }
        return false;
    }

    string actionId() {
        return _actionId;
    }

    string routeGroup() {
        return _routeGroup;
    }

    string guardName() {
        return _guardName;
    }

    /**
     * Flush all of the old input from the session.
     *
     * @return void
     */
    void flush() {
        if (_session !is null)
            _sessionStorage.put(_session);
    }

    /**
     * Gets the HttpSession.
     *
     * @return HttpSession|null The session
     */
    @property HttpSession session(bool canCreate = true) {
        if (_session !is null || isSessionRetrieved)
            return _session;

        string sessionId = this.cookie(DefaultSessionIdName);
        isSessionRetrieved = true;
        if (!sessionId.empty) {
            _session = _sessionStorage.get(sessionId);
            if(_session !is null) {
                _session.setMaxInactiveInterval(_sessionStorage.expire);
                version(HUNT_HTTP_DEBUG) {
                    tracef("session exists: %s, expire: %d", sessionId, _session.getMaxInactiveInterval());
                }
            }
        }

        if (_session is null && canCreate) {
            sessionId = HttpSession.generateSessionId();
            version(HUNT_DEBUG) infof("new session: %s, expire: %d", sessionId, _sessionStorage.expire);
            _session = HttpSession.create(sessionId, _sessionStorage.expire);
        }

        return _session;
    }

    private bool isSessionRetrieved = false;

    /**
     * Whether the request contains a HttpSession object.
     *
     * This method does not give any information about the state of the session object,
     * like whether the session is started or not. It is just a way to check if this Request
     * is associated with a HttpSession instance.
     *
     * @return bool true when the Request contains a HttpSession object, false otherwise
     */
    bool hasSession() {
        return session() !is null;
    }

    /**
     * Get the bearer token from the request headers.
     *
     * @return string
     */
    string bearerToken() {
        string v = _request.header("Authorization");
        if (startsWith(v, BearerTokenHeader)) {
            return v[BearerTokenHeader.length .. $];
        }
        return null;
    }

    /**
     * Get the basic token from the request headers.
     *
     * @return string
     */
    string basicToken() {
        string v = _request.header("Authorization");
        if (startsWith(v, BasicTokenHeader)) {
            return v[BasicTokenHeader.length .. $];
        }
        return null;
    }

    /**
     * Determine if the request contains a given input item key.
     *
     * @param  string|array key
     * @return bool
     */
    bool exists(string key) {
        return has([key]);
    }

    /**
     * Determine if the request contains a given input item key.
     *
     * @param  string|array  key
     * @return bool
     */
    bool has(string[] keys) {
        string[string] dict = this.all();
        foreach (string k; keys) {
            string* p = (k in dict);
            if (p is null)
                return false;
        }
        return true;
    }

    /**
     * Determine if the request contains any of the given inputs.
     *
     * @param  dynamic  key
     * @return bool
     */
    bool hasAny(string[] keys...) {
        string[string] dict = this.all();
        foreach (string k; keys) {
            string* p = (k in dict);
            if (p is null)
                return true;
        }
        return false;
    }

    /**
     * Determine if the request contains a non-empty value for an input item.
     *
     * @param  string|array  key
     * @return bool
     */
    bool filled(string[] keys) {
        foreach (string k; keys) {
            if (k.empty)
                return false;
        }

        return true;
    }

//     /**
//      * Get the keys for all of the input and files.
//      *
//      * @return array
//      */
//     string[] keys() {
//         // return this.input().keys ~ this.httpForm.fileKeys();
//         implementationMissing(false);
//         return this.input().keys;
//     }

    /**
     * Get all of the input and files for the request.
     *
     * @param  array|mixed  keys
     * @return array
     */
    string[string] all(string[] keys = null) {
        string[string] inputs = this.input();
        if (keys is null) {
            // HttpForm.FormFile[string]  files = this.allFiles;
            // foreach(string k; files.byKey)
            // {
            //     inputs[k] = files[k].fileName;
            // }
            return inputs;
        }

        string[string] results;
        foreach (string k; keys) {
            string* v = (k in inputs);
            if (v !is null)
                results[k] = *v;
        }
        return results;
    }

    /**
     * Retrieve an input item from the request.
     *
     * @param  string  key
     * @param  string|array|null  default
     * @return string|array
     */
    string input(string key, string defaults = null) {
        return getInputSource().get(key, defaults);
    }

    /// ditto
    string[string] input() {
        return getInputSource();
    }

    /**
     * Retrieve a cookie from the request.
     *
     * @param  string  key
     * @param  string|array|null  default
     * @return string|array
     */
    string cookie(string key, string defaultValue = null) {
        foreach (Cookie c; getCookies()) {
            if (c.getName == key)
                return c.getValue();
        }
        return defaultValue;
    }

    /**
     * Get an array of all of the files on the request.
     *
     * @return array
     */
    UploadedFile[] allFiles() {
        checkUploadedFiles();
        return _convertedAllFiles;
    }


    @property string methodAsString() {
        return _request.getMethod();
    }

    @property HttpMethod method() {
        return HttpMethod.fromString(_request.getMethod());
    }

    @property string url() {
        return _request.getURIString();
    }

    @property string fullUrl()
    {
        string str = format("%s://%s%s", getScheme(), _request.host(), _request.getURI().toString());
        return str;
    }

    @property string path() {
        return _request.getURI().getPath();
    }

//     @property string decodedPath() {
//         return _request.getURI().getDecodedPath();
//     }

    /**
     * Gets the request's scheme.
     *
     * @return string
     */
    string getScheme() {
        return _request.isHttps() ? "https" : "http";
    }


    protected string[string] getInputSource() {
        if (isContained(this.methodAsString, ["GET", "HEAD"]))
            return queries();
        else {
            string[string] r;
            foreach(string k, string[] v; xFormData()) {
                r[k] = v[0];
            }
            return r;
        }
    }

}


// version(WITH_HUNT_TRACE) {
//     import hunt.trace.Tracer;
// }


private Request _request;

Request request() {
    return _request;
}

void request(Request request) {
    _request = request;
}

HttpSession session() {
    return request().session();
}