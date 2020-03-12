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

import hunt.framework.file.UploadedFile;
import hunt.framework.http.session.SessionStorage;
import hunt.framework.provider.ServiceProvider;

import hunt.http.HttpMethod;
import hunt.http.HttpHeader;
import hunt.http.MultipartForm;
import hunt.http.server.HttpServerRequest;
import hunt.http.server.HttpSession;
import hunt.logging.ConsoleLogger;

import std.algorithm;
import std.range;

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

    HttpServerRequest _request;

    alias _request this;

    this(HttpServerRequest request) {
        this._request = request;
        _sessionStorage = serviceContainer().resolve!SessionStorage();
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

            if (_convertedMultiFiles !is null && _convertedMultiFiles.get(key, null) is null) {
                return false;
            }
            return true;
        }
    }

    private void checkUploadedFiles() {
        if (_convertedAllFiles.empty()) {
            convertUploadedFiles();
        }
    }

    private void convertUploadedFiles() {
        foreach (Part part; _request.getParts()) {
            MultipartForm multipart = cast(MultipartForm) part;

            version (HUNT_DEBUG) {
                tracef("File: key=%s, fileName=%s, actualFile=%s, ContentType=%s, content=%s",
                        multipart.getName(), multipart.getSubmittedFileName(),
                        multipart.getFile(), multipart.getContentType(),
                        cast(string) multipart.getBytes());
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

//     // alias _request this;
//     @property int elapsed()    {
//         Duration timeElapsed = MonoTime.currTime - _monoCreated;
//         return cast(int)timeElapsed.total!"msecs";
//     }

//     HttpURI getURI() {
//         return _request.getURI();
//     }

//     HttpFields getFields() {
//         return _httpFields;
//     }

//     private HttpFields _httpFields;

//     protected void handleQueryParameters() {
//         string q = getURI().getQuery();
//         if (!q.empty)
//             urlEncodedMap.decode(q);
//     }

//     package(hunt.framework) void onHeaderCompleted() {
//         _httpFields = _request.getFields();
//         string transferEncoding = _httpFields.get(HttpHeader.TRANSFER_ENCODING);
//         _contentLength = _request.getContentLength();

//         _isChunked = (HttpHeaderValue.CHUNKED.asString() == transferEncoding
//                 || (_request.getHttpVersion() == HttpVersion.HTTP_2
//                     && _contentLength < 0));

//         if(_isChunked) {
//             pipedStream = new ByteArrayPipedStream(4 * 1024);
//             // FIXME: Needing refactor or cleanup -@zhangxueping at 2019-10-16T11:01:18+08:00
//             // 
//         // } else if(contentLength > configuration.getBodyBufferThreshold()) {
//         //             pipedStream = new FilePipedStream(configuration.getTempFilePath());
//         } else if(_contentLength>0) {
//             pipedStream = new ByteArrayPipedStream(cast(int) _contentLength);
//         }
//     }

//     long getContentLength() {
//         return _contentLength;
//     }

//     private PipedStream pipedStream;
//     private long _contentLength = -1;

//     package(hunt.framework) void onContent(ByteBuffer buffer) {
//         version(HUNT_DEBUG) {
//             if(buffer.remaining() < 1024)
//                 info(BufferUtils.toString(buffer));
//         }
//         if(pipedStream is null)
//             requestBody.add(buffer);
//         else
//             pipedStream.getOutputStream().write(BufferUtils.toArray(buffer, false));
//     }

//     package(hunt.framework) void onContentCompleted() {
//         if(pipedStream is null)
//             return;

//         pipedStream.getOutputStream().close();
//         InputStream inputStream = pipedStream.getInputStream();
//         string contentType = MimeTypeUtils.getContentTypeMIMEType(_httpFields.get(HttpHeader.CONTENT_TYPE));
//         version (HUNT_DEBUG) info("content type: ", contentType);
//         contentType = contentType.toLower();

//         if (contentType == "application/x-www-form-urlencoded") {
//             _isXFormUrlencoded = true;
//             stringBody = IOUtils.toString(inputStream);
//             version (HUNT_DEBUG)
//                 trace("body content: ", stringBody);
//             urlEncodedMap.decode(stringBody); // getBodyAsString()
//             // version(HUNT_DEBUG) info(urlEncodedMap.toString());
//         } else if(contentType == "multipart/form-data") {
//             _isMultipart = true;
//             ApplicationConfig config = config();
//             string tempDir = DEFAULT_TEMP_PATH;
//             if(!tempDir.exists())
//                 tempDir.mkdirRecurse();
//             version (HUNT_DEBUG) info("temp dir for upload: ",tempDir);
//             // ByteBuffer buffer = requestBody.get(0);
//             // ByteArrayInputStream inputStream = new ByteArrayInputStream(BufferUtils.toArray(buffer));

//             this.convertUploadedFiles(new MultipartFormInputStream(inputStream, 
//                 _httpFields.get(HttpHeader.CONTENT_TYPE), config.multipartConfig, tempDir));
//         } else {
//             stringBody = IOUtils.toString(inputStream);
//             version (HUNT_DEBUG) {
//                 tracef("Do nothing for this content type: %s", contentType);
//                 // trace("body content: ", stringBody);
//             }
//         }
//     }

//     private void convertUploadedFiles(MultipartFormInputStream multipartForm)
//     {
//         foreach (Part part; multipartForm.getParts())
//         {
//             MultipartForm multipart = cast(MultipartForm) part;

//             version(HUNT_DEBUG) {
//                 tracef("File: key=%s, fileName=%s, actualFile=%s, ContentType=%s, content=%s",
//                     multipart.getName(), multipart.getSubmittedFileName(), 
//                     multipart.getFile(), multipart.getContentType(), cast(string) multipart.getBytes());
//             }

//             string contentType = multipart.getContentType();
//             string submittedFileName = multipart.getSubmittedFileName();
//             string key = multipart.getName();
//             if(!submittedFileName.empty) {
//                 // TODO: for upload failed? What's the errorCode? use multipart.isWriteToFile?
//                 int errorCode = 0;
//                 multipart.flush();
//                 auto file = new UploadedFile(multipart.getFile(), submittedFileName, 
//                     contentType, errorCode);

//                 this._convertedMultiFiles[key] ~= file;
//                 this._convertedAllFiles ~= file;
//             } else {
//                 this._xFormData[key] ~= cast(string) multipart.getBytes();
//             }
//         }
//     }

//     private bool _isMultipart = false;
//     private bool _isXFormUrlencoded = false;
//     private UploadedFile[] _convertedAllFiles;
//     private UploadedFile[][string] _convertedMultiFiles;

//     package(hunt.framework) void onMessageCompleted() {
//         version(HUNT_DEBUG_MORE) trace("do nothing");
//     }

//     bool isChunked() {
//         return _isChunked;
//     }

//     private bool _isChunked = false;

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

    // @property Address clientAddress() {
    //     return _connection.getTcpConnection().getRemoteAddress();
    // }

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

        // if(s.empty) {
        //     Address ad = clientAddress();
        //     s = ad.toAddrString();
        // }

        return s;
    }    

//     @property JSONValue json() {
//         if (_json == JSONValue.init)
//             _json = parseJSON(getBodyAsString());
//         return _json;
//     }

//     T json(T = string)(string key, T defaults = T.init) {
//         import std.traits;

//         auto obj = (key in (json().objectNoRef));
//         if (obj is null)
//             return defaults;

//         static if (isIntegral!(T))
//             return cast(T)((*obj).integer);
//         else static if (is(T == string))
//             return (*obj).str;
//         else static if (is(FloatingPointTypeOf!T X))
//             return cast(T)((*obj).floating);
//         else static if (is(T == bool)) {
//             if (obj.type == JSON_TYPE.TRUE)
//                 return true;
//             else if (obj.type == JSON_TYPE.FALSE)
//                 return false;
//             else {
//                 throw new Exception("json error");
//                 return false;
//             }
//         }
//         else {
//             return (*obj);
//         }
//     }

//     // get queries
//     @property ref string[string] queries() {
//         if (!_isQueryParamsSet) {
//             MultiMap!string map = new MultiMap!string();
//             getURI().decodeQueryTo(map);
//             foreach (string key, List!(string) values; map) {
//                 version(HUNT_DEBUG) {
//                     infof("query parameter: key=%s, values=%s", key, values[0]);
//                 }
//                 if(values is null || values.size()<1) {
//                     _queryParams[key] = ""; 
//                 } else {
//                     _queryParams[key] = values[0];
//                 }
//             }
//             _isQueryParamsSet = true;
//         }
//         return _queryParams;
//     }
//     private bool _isQueryParamsSet = false;

//     void putQueryParameter(string key, string value) {
//         version(HUNT_DEBUG) infof("query parameter: key=%s, values=%s", key, value);
//         _queryParams[key] = value;
//     }

//     private string[string] _queryParams;

//     @property string[][string] xFormData() {
//         if (_xFormData is null && _isXFormUrlencoded) {
//             UrlEncoded map = new UrlEncoded();
//             map.decode(stringBody);
//             foreach (string key; map.byKey()) {
//                 foreach(string v; map.getValues(key)) {
//                     key = key.strip();
//                     _xFormData[key] ~= v.strip();
//                 }
//             }
//         }
//         return _xFormData;
//     }

//     private string[][string] _xFormData;

//     T bindForm(T)() {

//         if(methodAsString() != "POST")
//             return T.init;
//         import hunt.serialization.JsonSerializer;
//         // import hunt.util.Serialize;

//         JSONValue jv;
//         if(xFormData() is null)
//             return new T();        
//         foreach(string k, string[] values; xFormData()) {
//             if(values.length > 1) {
//                 jv[k] = JSONValue(values);
//             } else if(values.length == 1) {
//                 jv[k] = JSONValue(values[0]);
//             } else {
//                 warningf("null value for %s in form data: ", k);
//             }
//         }
//         return JsonSerializer.toObject!T(jv);
//         // T obj = toObject!T(jv);

//         // return (obj is null) ? (new T()) : obj;
//     }

//     /**
//    * Sets the query parameter with the specified name to the specified value.
//    *
//    * Returns true if the query parameter was successfully set.
//    */
//     // void setQueryParameter(string name, string value) {
//     //     // parseQueryParams();
//     //     auto keyPtr = name in _queryParams;
//     //     if (keyPtr !is null)
//     //         logWarningf("A query is rewritten: %s", name);
//     //     _queryParams[name] = value;
//     // }

//     /// get a query
//     T get(T = string)(string key, T v = T.init) {
//         auto tmp = queries();
//         if (tmp is null) {
//             return v;
//         }
//         auto _v = tmp.get(key, "");
//         if (_v.length) {
//             return to!T(_v);
//         }
//         return v;
//     }

//     @property ref string[string] materef() {
//         return _mate;
//     }

//     HttpResponse getResponse() {
//         return _response;
//     }

//     alias getStringBody = getBodyAsString;

//     string getBodyAsString() {
//         if (stringBody is null) {
//             Appender!string buffer;
//             foreach (ByteBuffer b; requestBody) {
//                 buffer.put(BufferUtils.toString(b));
//             }
//             stringBody = buffer.data;
//             version (HUNT_DEBUG)
//                 trace("body content: ", stringBody);
//         }
//         return stringBody;
//     }

//     private string stringBody;

//     // Response createResponse()
//     // {
//     //     if (_error != HTTPErrorCode.NO_ERROR)
//     //     {
//     //         // throw new CreateResponseException("http error is : " ~ to!string(_error));
//     //         hunt.logging.warning("http error is : " ~ to!string(_error));
//     //     }
//     //     if (_res is null)
//     //         _res = new Response(_downstream);
//     //     return _res;
//     // }

//     @property void action(string value) {
//         _action = value;
//     }

//     @property string action() {
//         return _action;
//     }

//     @property bool isJson() {
//         string s = this.header(HttpHeader.CONTENT_TYPE);
//         return canFind(s, "/json") || canFind(s, "+json");
//     }

//     @property bool expectsJson() {
//         return (this.ajax && !this.pjax) || this.wantsJson();
//     }

//     /**
//      * Gets a list of content types acceptable by the client browser.
//      *
//      * @return array List of content types in preferable order
//      */
//     string[] getAcceptableContentTypes() {
//         if (acceptableContentTypes is null) {
//             acceptableContentTypes = getFields().getValuesList("Accept");
//         }

//         return acceptableContentTypes;
//     }

//     protected string[] acceptableContentTypes = null;

//     @property bool wantsJson() {
//         string[] acceptable = getAcceptableContentTypes();
//         if (acceptable is null)
//             return false;
//         return canFind(acceptable[0], "/json") || canFind(acceptable[0], "+json");
//     }

    private static bool isContained(string source, string[] keys) {
        foreach (string k; keys) {
            if (canFind(source, k))
                return true;
        }
        return false;
    }

//     @property bool accepts(string[] contentTypes) {
//         string[] acceptTypes = getAcceptableContentTypes();
//         if (acceptTypes is null)
//             return true;

//         string[] types = contentTypes;
//         foreach (string accept; acceptTypes) {
//             if (accept == "*/*" || accept == "*")
//                 return true;

//             foreach (string type; types) {
//                 size_t index = indexOf(type, "/");
//                 string name = type[0 .. index] ~ "/*";
//                 if (matchesType(accept, type) || accept == name)
//                     return true;
//             }
//         }
//         return false;
//     }

//     static bool matchesType(string actual, string type) {
//         if (actual == type) {
//             return true;
//         }

//         string[] split = split(actual, "/");

//         // TODO: Tasks pending completion -@zxp at 5/14/2018, 3:28:15 PM
//         // 
//         return split.length >= 2; // && preg_match('#'.preg_quote(split[0], '#').'/.+\+'.preg_quote(split[1], '#').'#', type);
//     }

//     @property string prefers(string[] contentTypes) {
//         string[] acceptTypes = getAcceptableContentTypes();

//         foreach (string accept; acceptTypes) {
//             if (accept == "*/*" || accept == "*")
//                 return acceptTypes[0];

//             foreach (string contentType; contentTypes) {
//                 string type = contentType;
//                 string mimeType = getMimeType(contentType);
//                 if (!mimeType.empty)
//                     type = mimeType;

//                 size_t index = indexOf(type, "/");
//                 string name = type[0 .. index] ~ "/*";
//                 if (matchesType(accept, type) || accept == name)
//                     return contentType;
//             }
//         }
//         return null;
//     }

//     /**
//      * Gets the mime type associated with the format.
//      *
//      * @param stringformat The format
//      *
//      * @return string The associated mime type (null if not found)
//      */
//     string getMimeType(string format) {
//         string[] r = getMimeTypes(format);
//         if (r is null)
//             return null;
//         else
//             return r[0];
//     }

//     /**
//      * Gets the mime types associated with the format.
//      *
//      * @param stringformat The format
//      *
//      * @return array The associated mime types
//      */
//     string[] getMimeTypes(string format) {
//         return formats.get(format, null);
//     }

//     /**
//      * Gets the format associated with the mime type.
//      *
//      * @param stringmimeType The associated mime type
//      *
//      * @return string|null The format (null if not found)
//      */
//     string getFormat(string mimeType) {
//         string canonicalMimeType = "";
//         ptrdiff_t index = indexOf(mimeType, ";");
//         if (index >= 0)
//             canonicalMimeType = mimeType[0 .. index];
//         foreach (string key, string[] value; formats) {
//             if (canFind(value, mimeType))
//                 return key;
//             if (!canonicalMimeType.empty && canFind(canonicalMimeType, mimeType))
//                 return key;
//         }

//         return null;
//     }

//     /**
//      * Associates a format with mime types.
//      *
//      * @param string      format    The format
//      * @param string|arraymimeTypes The associated mime types (the preferred one must be the first as it will be used as the content type)
//      */
//     void setFormat(string format, string[] mimeTypes) {
//         formats[format] = mimeTypes;
//     }

//     /**
//      * Gets the request format.
//      *
//      * Here is the process to determine the format:
//      *
//      *  * format defined by the user (with setRequestFormat())
//      *  * _format request attribute
//      *  *default
//      *
//      * @param stringdefault The default format
//      *
//      * @return string The request format
//      */
//     string getRequestFormat(string defaults = "html") {
//         if (_format.empty)
//             _format = this.mate.get("_format", null);

//         return _format is null ? defaults : _format;
//     }

//     /**
//      * Sets the request format.
//      *
//      * @param stringformat The request format
//      */
//     void setRequestFormat(string format) {
//         _format = format;
//     }

//     protected string _format;

//     /**
//      * Determine if the current request accepts any content type.
//      *
//      * @return bool
//      */
//     @property bool acceptsAnyContentType() {
//         string[] acceptable = getAcceptableContentTypes();

//         return acceptable.length == 0 || (acceptable[0] == "*/*" || acceptable[0] == "*");

//     }

//     @property bool acceptsJson() {
//         return accepts(["application/json"]);
//     }

//     @property bool acceptsHtml() {
//         return accepts(["text/html"]);
//     }

//     string format(string defaults = "html") {
//         string[] acceptTypes = getAcceptableContentTypes();

//         foreach (string type; acceptTypes) {
//             string r = getFormat(type);
//             if (!r.empty)
//                 return r;
//         }
//         return defaults;
//     }

//     /**
//      * Retrieve an old input item.
//      *
//      * @param  string  key
//      * @param  string|array|null  default
//      * @return string|array
//      */
//     // string[string] old(string[string] defaults = null)
//     // {
//     //     return this.hasSession() ? this.session().getOldInput(defaults) : defaults;
//     // }

//     // /// ditto
//     // string old(string key, string defaults = null)
//     // {
//     //     return this.hasSession() ? this.session().getOldInput(key, defaults) : defaults;
//     // }

//     /**
//      * Flash the input for the current request to the session.
//      *
//      * @return void
//      */
//     void flash() {
//         if (hasSession())
//             _session.flashInput(this.input());
//     }

//     /**
//      * Flash only some of the input to the session.
//      *
//      * @param  array|mixed  keys
//      * @return void
//      */
//     void flashOnly(string[] keys) {
//         if (hasSession())
//             _session.flashInput(this.only(keys));

//     }

//     /**
//      * Flash only some of the input to the session.
//      *
//      * @param  array|mixed  keys
//      * @return void
//      */
//     void flashExcept(string[] keys) {
//         if (hasSession())
//             _session.flashInput(this.only(keys));

//     }

    // string getMCA()
    // {
    //     string mca;
    //     if (request.route.getModule() is null)
    //     {
    //         mca = request.route.getController() ~ "." ~ request.route.getAction();
    //     }
    //     else
    //     {
    //         mca = request.route.getModule() ~ "." ~ request.route.getController()
    //             ~ "." ~ request.route.getAction();
    //     }
    //     return mca;
    // }

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
            _session.setMaxInactiveInterval(_sessionStorage.expire);
            version(HUNT_HTTP_DEBUG) {
                tracef("session exists: %s, expire: %d", sessionId, _session.getMaxInactiveInterval());
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

//     // string[] server(string key = null, string[] defaults = null) {
//     //     throw new NotImplementedException("server");
//     // }

//     /**
//      * Determine if a header is set on the request.
//      *
//      * @param  string key
//      * @return bool
//      */
//     bool hasHeader(string key) {
//         return getFields().containsKey(key);
//     }

//     /**
//      * Retrieve a header from the request.
//      *
//      * @param  string key
//      * @param  string|array|null default
//      * @return string|array
//      */
//     string[] header(string key = null, string[] defaults = null) {
//         string[] r = getFields().getValuesList(key);
//         if (r is null)
//             return defaults;
//         else
//             return r;
//     }

//     // ditto
//     string header(string key = null, string defaults = null) {
//         string r = getFields().get(key);
//         if (r is null)
//             return defaults;
//         else
//             return r;
//     }

    /**
     * Get the bearer token from the request headers.
     *
     * @return string|null
     */
    string bearerToken() {
        string v = _request.header("Authorization");
        if (startsWith(v, "Bearer ") >= 0)
            return v[7 .. $];
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

//     /**
//      * Get a subset containing the provided keys with values from the input data.
//      *
//      * @param  array|mixed  keys
//      * @return array
//      */
//     string[string] only(string[] keys) {
//         string[string] inputs = this.all();
//         string[string] results;
//         foreach (string k; keys) {
//             string* v = (k in inputs);
//             if (v !is null)
//                 results[k] = *v;
//         }

//         return results;
//     }

//     /**
//      * Get all of the input except for a specified array of items.
//      *
//      * @param  array|mixed  keys
//      * @return array
//      */
//     string[string] except(string[] keys) {
//         string[string] results = this.all();
//         foreach (string k; keys) {
//             string* v = (k in results);
//             if (v !is null)
//                 results.remove(k);
//         }

//         return results;
//     }

//     /**
//      * Retrieve a query string item from the request.
//      *
//      * @param  string  key
//      * @param  string|array|null  default
//      * @return string|array
//      */
//     string query(string key, string defaults = null) {
//         return queries().get(key, defaults);
//     }

//     /**
//      * Retrieve a request payload item from the request.
//      *
//      * @param  string  key
//      * @param  string|array|null  default
//      *
//      * @return string|array
//      */
//     T post(T = string)(string key, T v = T.init) {
//         string[][string] form = xFormData();
//         if (form is null)
//             return v;
//         if(key in form) {
//             string[] _v = form[key];
//             if (_v.length > 0) {
//                 static if(is(T == string))
//                     v = _v[0];
//                 else {
//                     v = to!T(_v[0]);
//                 }
//             } 
//         } 

//         return v;
//     }

//     T[] posts(T = string)(string key, T[] v = null) {
//         string[][string] form = xFormData();
//         if (form is null)
//             return v;

//         if(key in form) {
//             string[] _v = form[key];
//             if (_v.length > 0) {
//                 static if(is(T == string))
//                     v = _v[];
//                 else {
//                     v = new T[_v.length];
//                     for(size i =0; i<v.length; i++) {
//                         v[i] = to!T(_v[i]);
//                     }
//                 }
//             } 
//         } 

//         return v;
//     }

//     /**
//      * Determine if a cookie is set on the request.
//      *
//      * @param  string  key
//      * @return bool
//      */
//     // bool hasCookie(string key)
//     // {
//     //     // return cookie(key).length > 0;
//     //     foreach(Cookie c; _cookies) {
//     //         if(c.getName == key)
//     //             return true;
//     //     }
//     //     return false;
//     // }

//     // bool hasCookie()
//     // {
//     //     return _cookies.length > 0;
//     // }

//     /**
//      * Retrieve a cookie from the request.
//      *
//      * @param  string  key
//      * @param  string|array|null  default
//      * @return string|array
//      */
//     string cookie(string key, string defaultValue = null) {
//         // return cookieManager.get(key, defaultValue);
//         foreach (Cookie c; getCookies()) {
//             if (c.getName == key)
//                 return c.getValue();
//         }
//         return defaultValue;
//     }

//     Cookie[] getCookies() {
//         if (_cookies is null) {
//             Array!(Cookie) list;
//             foreach (string v; getFields().getValuesList(HttpHeader.COOKIE)) {
//                 if (v.empty)
//                     continue;
//                 foreach (Cookie c; CookieParser.parseCookie(v))
//                     list.insertBack(c);
//             }
//             _cookies = list.array();
//         }
//         return _cookies;
//     }

//     /**
//      * Retrieve  users' own preferred language.
//      */
//     string locale()
//     {
//         string l;
//         l = cookie("Content-Language");
//         if(l is null)
//             l = config().application.defaultLanguage;

//         return toLower(l);
//     }
//     /**
//      * Get an array of all cookies.
//      *
//      * @return array
//      */
//     // string[string] cookie()
//     // {
//     //     // return cookieManager.requestCookies();

//     //     implementationMissing(false);
//     //     return null;
//     // }

//     /**
//      * Get an array of all of the files on the request.
//      *
//      * @return array
//      */
//     UploadedFile[] allFiles() {
//         return _convertedAllFiles;
//     }

//     /**
//      * Determine if the uploaded data contains a file.
//      *
//      * @param  string  key
//      * @return bool
//      */
//     bool hasFile(string key) {
//         if(_convertedMultiFiles is null) {
//             return false;
//         } else {
//             if (_convertedMultiFiles.get(key, null) is null)
//             {
//                 return false;
//             }
//             return true;
//         }
//     }

//     /**
//      * Retrieve a file from the request.
//      *
//      * @param  string  key
//      * @param  mixed default
//      * @return UploadedFile
//      */
//     UploadedFile file(string key)
//     {
//         if (this.hasFile(key))
//         {
//             return this._convertedMultiFiles[key][0];
//         }

//         return null;
//     }

//     UploadedFile[] files(string key)
//     {
//         if (this.hasFile(key))
//         {
//             return this._convertedMultiFiles[key];
//         }

//         return null;
//     }

    @property string methodAsString() {
        return _request.getMethod();
    }

    @property HttpMethod method() {
        return HttpMethod.fromString(_request.getMethod());
    }

    @property string url() {
        return _request.getURIString();
    }

//     // @property string fullUrl()
//     // {
//     //     return _httpMessage.url();
//     // }

//     // @property string fullUrlWithQuery()
//     // {
//     //     return _httpMessage.url();
//     // }

    @property string path() {
        return _request.getURI().getPath();
    }

//     @property string decodedPath() {
//         return _request.getURI().getDecodedPath();
//     }

//     /**
//      * Gets the request's scheme.
//      *
//      * @return string
//      */
//     string getScheme() {
//         return isSecure() ? "https" : "http";
//     }

//     /**
//      * Get a segment from the URI (1 based index).
//      *
//      * @param  int  index
//      * @param  string|null  default
//      * @return string|null
//      */
//     string segment(int index, string defaults = null) {
//         string[] s = segments();
//         if (s.length <= index || index <= 0)
//             return defaults;
//         return s[index - 1];
//     }

//     /**
//      * Get all of the segments for the request path.
//      *
//      * @return array
//      */
//     string[] segments() {
//         string[] t = decodedPath().split("/");
//         string[] r;
//         foreach (string v; t) {
//             if (!v.empty)
//                 r ~= v;
//         }
//         return r;
//     }

//     /**
//      * Determine if the current request URI matches a pattern.
//      *
//      * @param  patterns
//      * @return bool
//      */
//     bool uriIs(string[] patterns...) {
//         string path = decodedPath();

//         foreach (string pattern; patterns) {
//             auto s = matchAll(path, regex(pattern));
//             if (!s.empty)
//                 return true;
//         }
//         return false;
//     }

//     /**
//      * Determine if the route name matches a given pattern.
//      *
//      * @param  dynamic  patterns
//      * @return bool
//      */
//     bool routeIs(string[] patterns...) {
//         if (_route !is null) {
//             string r = _route.getRoute();
//             foreach (string pattern; patterns) {
//                 auto s = matchAll(r, regex(pattern));
//                 if (!s.empty)
//                     return true;
//             }
//         }
//         return false;
//     }

//     /**
//      * Determine if the current request URL and query string matches a pattern.
//      *
//      * @param  dynamic  patterns
//      * @return bool
//      */
//     // bool fullUrlIs(string[] patterns...)
//     // {
//     //     string r = this.fullUrl();
//     //     foreach (string pattern; patterns)
//     //     {
//     //         auto s = matchAll(r, regex(pattern));
//     //         if (!s.empty)
//     //             return true;
//     //     }

//     //     return false;
//     // }

//     /**
//      * Determine if the request is the result of an AJAX call.
//      *
//      * @return bool
//      */
//     @property bool ajax() {
//         return getFields().get("X-Requested-With") == "XMLHttpRequest";
//     }

//     /**
//      * Determine if the request is the result of an PJAX call.
//      *
//      * @return bool
//      */
//     @property bool pjax() {
//         return getFields().containsKey("X-PJAX");
//     }

//     /**
//      * Determine if the request is over HTTPS.
//      *
//      * @return bool
//      */
//     @property bool secure() {
//         return isSecure();
//     }

//     /**
//      * Checks whether the request is secure or not.
//      *
//      * This method can read the client protocol from the "X-Forwarded-Proto" header
//      * when trusted proxies were set via "setTrustedProxies()".
//      *
//      * The "X-Forwarded-Proto" header must contain the protocol: "https" or "http".
//      *
//      * @return bool
//      */
//     @property bool isSecure() {
//         throw new NotImplementedException("isSecure");
//     }

//     /**
//      * Get the client IP address.
//      *
//      * @return string
//      */
//     // @property string ip()
//     // {
//     //     return _httpMessage.getClientIP();
//     // }

//     /**
//      * Get the client IP addresses.
//      *
//      * @return array
//      */
//     // @property string[] ips()
//     // {
//     //     throw new NotImplementedException("ips");
//     // }

//     /**
//      * Get the client user agent.
//      *
//      * @return string
//      */
//     @property string userAgent() {
//         return getFields().get("User-Agent");
//     }

//     Request merge(string[] input) {
//         string[string] inputSource = getInputSource;
//         for (size_t i = 0; i < input.length; i++) {
//             inputSource[to!string(i)] = input[i];
//         }
//         return this;
//     }

//     /**
//      * Replace the input for the current request.
//      *
//      * @param  array input
//      * @return Request
//      */
//     Request replace(string[string] input) {
//         if (isContained(this.methodAsString, ["GET", "HEAD"]))
//             _queryParams = input;
//         else {
//             foreach(string k, string v; input) {
//                 _xFormData[k] ~= v;
//             }
//         }

//         return this;
//     }

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

//     /**
//      * Get the user making the request.
//      *
//      * @param  string|null guard
//      * @return User
//      */
//     @property User user() {
//         return this._user;
//     }

//     // ditto
//     @property void user(User user) {
//         this._user = user;
//     }

//     /**
//      * Get the route handling the request.
//      *
//      * @param  string|null param
//      *
//      * @return Route
//      */
//     @property Route route() {
//         return _route;
//     }

//     // ditto
//     @property void route(Route value) {
//         _route = value;
//     }

//     /**
//      * Get a unique fingerprint for the request / route / IP address.
//      *
//      * @return string
//      */
//     // string fingerprint()
//     // {
//     //     if(_route is null)
//     //         throw new Exception("Unable to generate fingerprint. Route unavailable.");

//     //     string[] r ;
//     //     foreach(HTTP_METHODS m;  _route.getMethods())
//     //         r ~= to!string(m);
//     //     r ~= _route.getUrlTemplate();
//     //     r ~= this.ip();

//     //     return toHexString(sha1Of(join(r, "|"))).idup;
//     // }

//     /**
//      * Set the JSON payload for the request.
//      *
//      * @param json
//      * @returnthis
//      */
//     Request setJson(string[string] json) {
//         _json = JSONValue(json);
//         return this;
//     }

//     /**
//      * Get the user resolver callback.
//      *
//      * @return Closure
//      */
//     Closure getUserResolver() {
//         if (userResolver is null)
//             return (Request) {  };

//         return userResolver;
//     }

//     /**
//      * Set the user resolver callback.
//      *
//      * @param  Closure callback
//      * @returnthis
//      */
//     Request setUserResolver(Closure callback) {
//         userResolver = callback;
//         return this;
//     }

//     /**
//      * Get the route resolver callback.
//      *
//      * @return Closure
//      */
//     Closure getRouteResolver() {
//         if (routeResolver is null)
//             return (Request) {  };

//         return routeResolver;
//     }

//     /**
//      * Set the route resolver callback.
//      *
//      * @param  Closure callback
//      * @returnthis
//      */
//     Request setRouteResolver(Closure callback) {
//         routeResolver = callback;
//         return this;
//     }

//     /**
//      * Get all of the input and files for the request.
//      *
//      * @return array
//      */
//     string[string] toArray() {
//         return this.all();
//     }

//     /**
//      * Determine if the given offset exists.
//      *
//      * @param  string offset
//      * @return bool
//      */
//     bool offsetExists(string offset) {
//         string[string] a = this.all();
//         string* p = (offset in a);

//         if (p is null)
//             return this.route.hasParameter(offset);
//         else
//             return true;

//     }

//     string offsetGet(string offset) {
//         return __get(offset);
//     }

//     /**
//      * Set the value at the given offset.
//      *
//      * @param  string offset
//      * @param  mixed value
//      * @return void
//      */
//     void offsetSet(string offset, string value) {
//         string[string] dict = this.getInputSource();
//         dict[offset] = value;
//     }

//     /**
//      * Remove the value at the given offset.
//      *
//      * @param  string offset
//      * @return void
//      */
//     void offsetUnset(string offset) {
//         string[string] dict = this.getInputSource();
//         dict.remove(offset);
//     }

//     /**
//      * Check if an input element is set on the request.
//      *
//      * @param  string  key
//      * @return bool
//      */
//     protected bool __isset(string key) {
//         string v = __get(key);
//         return !v.empty;
//     }

//     /**
//      * Get an input element from the request.
//      *
//      * @param  string  key
//      * @return string
//      */
//     protected string __get(string key) {
//         string[string] a = this.all();
//         string* p = (key in a);

//         if (p is null) {
//             return this.route.getParameter(key);
//         }
//         else
//             return *p;
//     }

//     /**
//      * Returns the protocol version.
//      *
//      * If the application is behind a proxy, the protocol version used in the
//      * requests between the client and the proxy and between the proxy and the
//      * server might be different. This returns the former (from the "Via" header)
//      * if the proxy is trusted (see "setTrustedProxies()"), otherwise it returns
//      * the latter (from the "SERVER_PROTOCOL" server parameter).
//      *
//      * @return string
//      */
//     string getProtocolVersion() {
//         return _request.getHttpVersion().toString();
//     }

//     /**
//      * Indicates whether this request originated from a trusted proxy.
//      *
//      * This can be useful to determine whether or not to trust the
//      * contents of a proxy-specific header.
//      *
//      * @return bool true if the request came from a trusted proxy, false otherwise
//      */
//     // bool isFromTrustedProxy() {
//     //     implementationMissing(false);
//     //     return false;
//     // }

//     Object getAttribute(string name) {
//         auto itemPtr = name in _attributes;
//         if(itemPtr is null)
//             return null;
//         return *itemPtr;
//     }

//     void setAttribute(string name, Object o) {
//         this._attributes[name] = o;
//     }

}

// import hunt.http.codec.http.model;
// import hunt.http.HttpConnection;
// import hunt.http.codec.http.stream.HttpOutputStream;
// import hunt.net.util.UrlEncoded;

// import hunt.collection;
// import hunt.io;
// import hunt.logging;
// import hunt.Exceptions;
// import hunt.util.Common;
// import hunt.util.MimeTypeUtils;

// import hunt.framework.application.ApplicationConfig;
// import hunt.framework.Simplify;
// import hunt.framework.Exceptions;
// import hunt.framework.http.session;
// import hunt.framework.Init;
// import hunt.framework.routing.Route;
// import hunt.framework.routing.Define;
// import hunt.framework.security.acl.User;
// import hunt.framework.file.UploadedFile;
// import hunt.Functions;

// import core.time : MonoTime, Duration;
// import std.algorithm;
// import std.array;
// import std.container.array;
// import std.conv;
// import std.digest;
// import std.digest.sha;
// import std.exception;
// import std.file;
// import std.json;
// import std.path;
// import std.regex;
// import std.string;
// import std.socket : Address;

// version(WITH_HUNT_TRACE) {
//     import hunt.trace.Tracer;
// }

// alias RequestEventHandler = void delegate(Request sender);
// alias Closure = RequestEventHandler;

// final class Request {
//     private HttpRequest _request;
//     private HttpResponse _response;
//     private SessionStorage _sessionStorage;

//     private UrlEncoded urlEncodedMap;
//     private Cookie[] _cookies;
//     private HttpSession _session;
//     private MonoTime _monoCreated;
//     private Object[string] _attributes;

//     HttpConnection _connection;
//     // Action1!ByteBuffer content;
//     // Action1!Request contentComplete;
//     // Action1!Request messageComplete;
//     package(hunt.framework.http) HttpOutputStream outputStream;
//     package(hunt.framework) List!(ByteBuffer) requestBody;

//     RequestEventHandler routeResolver;
//     RequestEventHandler userResolver;

//     this(HttpRequest request, HttpResponse response, HttpOutputStream output,
//             HttpConnection connection, SessionStorage sessionStorage) {
//         _monoCreated = MonoTime.currTime;
//         requestBody = new ArrayList!(ByteBuffer)();
//         this._request = request;
//         this.outputStream = output;
//         this._response = response;
//         this._connection = connection;
//         this._sessionStorage = sessionStorage;
//         this.urlEncodedMap = new UrlEncoded();
//         // response.setStatus(HttpStatus.OK_200);
//         // response.setHttpVersion(HttpVersion.HTTP_1_1);
//         // this._response = new Response(response, output, request.getURI(), bufferSize);
//         handleQueryParameters();

//         .request(this);
//     }

// version(WITH_HUNT_TRACE) {
//     Tracer tracer;
// }

//     // enum string Subject = "subject";

// private:
//     User _user;
//     Route _route;
//     string _stringBody;
//     string[string] _mate;
//     // CookieManager _cookieManager;
//     JSONValue _json;
//     string _action;
// }

// void setTrustedProxies(string[] proxies, int headerSet) {
//     trustedProxies = proxies;
//     trustedHeaderSet = headerSet;
// }

// package {
//     string[][string] formats;
//     string[] trustedProxies;
//     int trustedHeaderSet;

//     const HEADER_FORWARDED = 0b00001; // When using RFC 7239
//     const HEADER_X_FORWARDED_FOR = 0b00010;
//     const HEADER_X_FORWARDED_HOST = 0b00100;
//     const HEADER_X_FORWARDED_PROTO = 0b01000;
//     const HEADER_X_FORWARDED_PORT = 0b10000;
//     const HEADER_X_FORWARDED_ALL = 0b11110; // All "X-Forwarded-*" headers
//     const HEADER_X_FORWARDED_AWS_ELB = 0b11010; // AWS ELB doesn"t send X-Forwarded-Host
// }

// static this() {
//     formats["html"] = ["text/html", "application/xhtml+xml"];
//     formats["txt"] = ["text/plain"];
//     formats["js"] = ["application/javascript", "application/x-javascript", "text/javascript"];
//     formats["css"] = ["text/css"];
//     formats["json"] = ["application/json", "application/x-json"];
//     formats["jsonld"] = ["application/ld+json"];
//     formats["xml"] = ["text/xml", "application/xml", "application/x-xml"];
//     formats["rdf"] = ["application/rdf+xml"];
//     formats["atom"] = ["application/atom+xml"];
//     formats["rss"] = ["application/rss+xml"];
//     formats["form"] = ["application/x-www-form-urlencoded"];
// }

// private Request _request;

// Request request() {
//     return _request;
// }

// void request(Request request) {
//     _request = request;
// }

// HttpSession session() {
//     return request().session();
// }

// string session(string key) {
//     return session().get(key);
// }

// void session(string[string] values) {
//     foreach (key, value; values) {
//         session().put(key, value);
//     }
// }
