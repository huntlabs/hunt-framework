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

module hunt.framework.http.Request;

import hunt.http.codec.http.model;

// import hunt.http.codec.http.stream;
import hunt.http.codec.http.stream.HttpConnection;
import hunt.http.codec.http.stream.HttpOutputStream;

import hunt.container;
import hunt.logging;
import hunt.util.exception;
import hunt.util.functional;

import hunt.framework.exception;
import hunt.framework.http.session;
import hunt.framework.routing.route;
import hunt.framework.routing.define;
import hunt.framework.security.acl.User;

import std.algorithm;
import std.array;
import std.container.array;
import std.conv;
import std.digest;
import std.digest.sha;
import std.exception;
import std.json;
import std.regex;
import std.string;
import std.socket : Address;

alias RequestEventHandler = void delegate(Request sender);
alias Closure = RequestEventHandler;


final class Request {
	private HttpRequest _request;
	private HttpResponse _response;
	private SessionStorage _sessionStorage;
	package(hunt.framework.http) HttpOutputStream outputStream;

	HttpConnection _connection;
	Action1!ByteBuffer content;
	Action1!Request contentComplete;
	Action1!Request messageComplete;
	List!(ByteBuffer) requestBody;

	private Cookie[] _cookies;
	string stringBody;

	RequestEventHandler routeResolver;
	RequestEventHandler userResolver;

	protected HttpSession _session;
	// protected string _sessionId;

	this(HttpRequest request, HttpResponse response, HttpOutputStream output,
			HttpConnection connection, SessionStorage sessionStorage) {
		requestBody = new ArrayList!(ByteBuffer)();
		this._request = request;
		this.outputStream = output;
		this._response = response;
		this._connection = connection;
		this._sessionStorage = sessionStorage;
		// response.setStatus(HttpStatus.OK_200);
		// response.setHttpVersion(HttpVersion.HTTP_1_1);
		// this._response = new Response(response, output, request.getURI(), bufferSize);
	}

	// alias _request this;

	HttpURI getURI() {
		return _request.getURI();
	}

	HttpFields getFields() {
		return _request.getFields();
	}

	// string sessionId() {
	// 	return this._sessionId;
	// }

	/**
     * Custom parameters.
     */
	@property string[string] mate() {
		return _mate;
	}

	string getMate(string key, string value = null) {
		return _mate.get(key, value);
	}

	void addMate(string key, string value) {
		_mate[key] = value;
	}

	@property string host() {
		return header(HttpHeader.HOST);
	}

	string header(HttpHeader code) {
		return getFields().get(code);
	}

	string header(string key) {
		return getFields().get(key);
	}

	bool headerExists(HttpHeader code) {
		return getFields().contains(code);
	}

	bool headerExists(string key) {
		return getFields().containsKey(key);
	}

	// int headersForeach(scope int delegate(string key, string value) each)
	// {
	// 	return getFields().opApply(each);
	// }

	// int headersForeach(scope int delegate(HttpHeader code, string key, string value) each)
	// {
	// 	return getFields().opApply(each);
	// }

	// bool headerValueForeach(string name, scope bool delegate(string value) func)
	// {
	// 	return getFields().forEachValueOfHeader(name, func);
	// }

	// bool headerValueForeach(HttpHeader code, scope bool delegate(string value) func)
	// {
	// 	return getFields().forEachValueOfHeader(code, func);
	// }

	@property string referer() {
		string rf = header("Referer");
		string[] rfarr = split(rf, ", ");
		if (rfarr.length) {
			return rfarr[0];
		}
		return "";
	}

	@property Address clientAddress() {
		return _connection.getLocalAddress();
	}

	@property JSONValue json() {
		if (_json == JSONValue.init)
			_json = parseJSON(getStringBody());
		return _json;
	}

	T json(T = string)(string key, T defaults = T.init) {
		import std.traits;

		auto obj = (key in (json().objectNoRef));
		if (obj is null)
			return defaults;

		static if (isIntegral!(T))
			return cast(T)((*obj).integer);
		else static if (is(T == string))
			return (*obj).str;
		else static if (is(FloatingPointTypeOf!T X))
			return cast(T)((*obj).floating);
		else static if (is(T == bool)) {
			if (obj.type == JSON_TYPE.TRUE)
				return true;
			else if (obj.type == JSON_TYPE.FALSE)
				return false;
			else {
				throw new Exception("json error");
				return false;
			}
		}
		else {
			return (*obj);
		}
	}

	///get queries
	@property string[string] queries() {
		if(_queryParams is null) {
			MultiMap!string map = new MultiMap!string();
			getURI().decodeQueryTo(map);
			foreach(string key; map.byKey()) {
				_queryParams[key] = map.getValue(key, 0);
			}
		}
		return _queryParams;
	}

	private string[string] _queryParams;

	/**
   * Sets the query parameter with the specified name to the specified value.
   *
   * Returns true if the query parameter was successfully set.
   */
	// void setQueryParameter(string name, string value) {
	// 	// parseQueryParams();
	// 	auto keyPtr = name in _queryParams;
	// 	if (keyPtr !is null)
	// 		logWarningf("A query is rewritten: %s", name);
	// 	_queryParams[name] = value;
	// }

	/// get a query
	T get(T = string)(string key, T v = T.init) {
		auto tmp = queries();
		if (tmp is null) {
			return v;
		}
		auto _v = tmp.get(key, "");
		if (_v.length) {
			return to!T(_v);
		}
		return v;
	}

	@property ref string[string] materef() {
		return _mate;
	}

	HttpResponse getResponse() {
		return _response;
	}

	string getStringBody() {
		if (stringBody is null) {
			Appender!string buffer;
			foreach (ByteBuffer b; requestBody) {
				buffer.put(cast(string) b.array);
			}
			stringBody = buffer.data;
		}
		return stringBody;
	}

	// Response createResponse()
	// {
	// 	if (_error != HTTPErrorCode.NO_ERROR)
	// 	{
	// 		// throw new CreateResponseException("http error is : " ~ to!string(_error));
	// 		hunt.logging.warning("http error is : " ~ to!string(_error));
	// 	}
	// 	if (_res is null)
	// 		_res = new Response(_downstream);
	// 	return _res;
	// }

	@property void action(string value) {
		_action = value;
	}

	@property string action() {
		return _action;
	}

	@property bool isJson() {
		string s = this.header(HttpHeader.CONTENT_TYPE);
		return canFind(s, "/json") || canFind(s, "+json");
	}

	@property bool expectsJson() {
		return (this.ajax && !this.pjax) || this.wantsJson();
	}

	/**
     * Gets a list of content types acceptable by the client browser.
     *
     * @return array List of content types in preferable order
     */
	public string[] getAcceptableContentTypes() {
		if (acceptableContentTypes is null) {
			acceptableContentTypes = getFields().getValuesList("Accept");
		}

		return acceptableContentTypes;
	}

	protected string[] acceptableContentTypes = null;

	@property bool wantsJson() {
		string[] acceptable = getAcceptableContentTypes();
		if (acceptable is null)
			return false;
		return canFind(acceptable[0], "/json") || canFind(acceptable[0], "+json");
	}

	private static bool isContained(string source, string[] keys) {
		foreach (string k; keys) {
			if (canFind(source, k))
				return true;
		}
		return false;
	}

	@property bool accepts(string[] contentTypes) {
		string[] acceptTypes = getAcceptableContentTypes();
		if (acceptTypes is null)
			return true;

		string[] types = contentTypes;
		foreach (string accept; acceptTypes) {
			if (accept == "*/*" || accept == "*")
				return true;

			foreach (string type; types) {
				size_t index = indexOf(type, "/");
				string name = type[0 .. index] ~ "/*";
				if (matchesType(accept, type) || accept == name)
					return true;
			}
		}
		return false;
	}

	static bool matchesType(string actual, string type) {
		if (actual == type) {
			return true;
		}

		string[] split = split(actual, "/");

		// TODO: Tasks pending completion -@zxp at 5/14/2018, 3:28:15 PM
		// 
		return split.length >= 2; // && preg_match('#'.preg_quote(split[0], '#').'/.+\+'.preg_quote(split[1], '#').'#', type);
	}

	@property string prefers(string[] contentTypes) {
		string[] acceptTypes = getAcceptableContentTypes();

		foreach (string accept; acceptTypes) {
			if (accept == "*/*" || accept == "*")
				return acceptTypes[0];

			foreach (string contentType; contentTypes) {
				string type = contentType;
				string mimeType = getMimeType(contentType);
				if (!mimeType.empty)
					type = mimeType;

				size_t index = indexOf(type, "/");
				string name = type[0 .. index] ~ "/*";
				if (matchesType(accept, type) || accept == name)
					return contentType;
			}
		}
		return null;
	}

	/**
     * Gets the mime type associated with the format.
     *
     * @param stringformat The format
     *
     * @return string The associated mime type (null if not found)
     */
	string getMimeType(string format) {
		string[] r = getMimeTypes(format);
		if (r is null)
			return null;
		else
			return r[0];
	}

	/**
     * Gets the mime types associated with the format.
     *
     * @param stringformat The format
     *
     * @return array The associated mime types
     */
	string[] getMimeTypes(string format) {
		return formats.get(format, null);
	}

	/**
     * Gets the format associated with the mime type.
     *
     * @param stringmimeType The associated mime type
     *
     * @return string|null The format (null if not found)
     */
	string getFormat(string mimeType) {
		string canonicalMimeType = "";
		ptrdiff_t index = indexOf(mimeType, ";");
		if (index >= 0)
			canonicalMimeType = mimeType[0 .. index];
		foreach (string key, string[] value; formats) {
			if (canFind(value, mimeType))
				return key;
			if (!canonicalMimeType.empty && canFind(canonicalMimeType, mimeType))
				return key;
		}

		return null;
	}

	/**
     * Associates a format with mime types.
     *
     * @param string      format    The format
     * @param string|arraymimeTypes The associated mime types (the preferred one must be the first as it will be used as the content type)
     */
	void setFormat(string format, string[] mimeTypes) {
		formats[format] = mimeTypes;
	}

	/**
     * Gets the request format.
     *
     * Here is the process to determine the format:
     *
     *  * format defined by the user (with setRequestFormat())
     *  * _format request attribute
     *  *default
     *
     * @param stringdefault The default format
     *
     * @return string The request format
     */
	string getRequestFormat(string defaults = "html") {
		if (_format.empty)
			_format = this.mate.get("_format", null);

		return _format is null ? defaults : _format;
	}

	/**
     * Sets the request format.
     *
     * @param stringformat The request format
     */
	void setRequestFormat(string format) {
		_format = format;
	}

	protected string _format;

	/**
     * Determine if the current request accepts any content type.
     *
     * @return bool
     */
	@property bool acceptsAnyContentType() {
		string[] acceptable = getAcceptableContentTypes();

		return acceptable.length == 0 || (acceptable[0] == "*/*" || acceptable[0] == "*");

	}

	@property bool acceptsJson() {
		return accepts(["application/json"]);
	}

	@property bool acceptsHtml() {
		return accepts(["text/html"]);
	}

	string format(string defaults = "html") {
		string[] acceptTypes = getAcceptableContentTypes();

		foreach (string type; acceptTypes) {
			string r = getFormat(type);
			if (!r.empty)
				return r;
		}
		return defaults;
	}

	/**
     * Retrieve an old input item.
     *
     * @param  string  key
     * @param  string|array|null  default
     * @return string|array
     */
	// public string[string] old(string[string] defaults = null)
	// {
	// 	return this.hasSession() ? this.session().getOldInput(defaults) : defaults;
	// }

	// /// ditto
	// public string old(string key, string defaults = null)
	// {
	// 	return this.hasSession() ? this.session().getOldInput(key, defaults) : defaults;
	// }

	/**
     * Flash the input for the current request to the session.
     *
     * @return void
     */
	public void flash() {
		// this.session().flashInput(this.input());
		implementationMissing(false);
	}

	/**
     * Flash only some of the input to the session.
     *
     * @param  array|mixed  keys
     * @return void
     */
	public void flashOnly(string[] keys) {
		// this.session().flashInput(this.only(keys));

		implementationMissing(false);
	}

	/**
     * Flash only some of the input to the session.
     *
     * @param  array|mixed  keys
     * @return void
     */
	public void flashExcept(string[] keys) {
		// this.session().flashInput(this.only(keys));

		implementationMissing(false);
	}

	/**
     * Flush all of the old input from the session.
     *
     * @return void
     */
	void flush() {
		if(hasSession())
			_sessionStorage.put(_session);
	}

	/**
     * Gets the HttpSession.
     *
     * @return HttpSession|null The session
     */
	@property HttpSession session(bool canCreate = false) {
		if (_session !is null || isSessionRetrieved) 
			return _session;

		string sessionId = this.cookie(DefaultSessionIdName);
		isSessionRetrieved = true;
		if (!sessionId.empty) {
			_session = _sessionStorage.get(sessionId);
		}

		if(_session is null && canCreate) {
			sessionId = HttpSession.generateSessionId();
			_session = HttpSession.create(sessionId, _sessionStorage.expire);
			// _sessionStorage.put(sessionId, _session);
		}

		return _session;
	}
	private bool isSessionRetrieved = false;

	// @property void session(HttpSession session) {
	// 	this._session = session;
	// }

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

	// string[] server(string key = null, string[] defaults = null) {
	// 	throw new NotImplementedException("server");
	// }

	/**
     * Determine if a header is set on the request.
     *
     * @param  string key
     * @return bool
     */
	bool hasHeader(string key) {
		return getFields().containsKey(key);
	}

	/**
     * Retrieve a header from the request.
     *
     * @param  string key
     * @param  string|array|null default
     * @return string|array
     */
	string[] header(string key = null, string[] defaults = null) {
		string[] r = getFields().getValuesList(key);
		if (r is null)
			return defaults;
		else
			return r;
	}

	// ditto
	string header(string key = null, string defaults = null) {
		string r = getFields().get(key);
		if (r is null)
			return defaults;
		else
			return r;
	}

	/**
     * Get the bearer token from the request headers.
     *
     * @return string|null
     */
	string bearerToken() {
		string v = header("Authorization", "");
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

	/**
     * Get the keys for all of the input and files.
     *
     * @return array
     */
	string[] keys() {
		// return this.input().keys ~ this.httpForm.fileKeys();
		implementationMissing(false);
		return this.input().keys;
	}

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
			// 	inputs[k] = files[k].fileName;
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
     * Get a subset containing the provided keys with values from the input data.
     *
     * @param  array|mixed  keys
     * @return array
     */
	string[string] only(string[] keys) {
		string[string] inputs = this.all();
		string[string] results;
		foreach (string k; keys) {
			string* v = (k in inputs);
			if (v !is null)
				results[k] = *v;
		}

		return results;
	}

	/**
     * Get all of the input except for a specified array of items.
     *
     * @param  array|mixed  keys
     * @return array
     */
	string[string] except(string[] keys) {
		string[string] results = this.all();
		foreach (string k; keys) {
			string* v = (k in results);
			if (v !is null)
				results.remove(k);
		}

		return results;
	}

	/**
     * Retrieve a query string item from the request.
     *
     * @param  string  key
     * @param  string|array|null  default
     * @return string|array
     */
	string query(string key, string defaults = null) {
		return queries().get(key, defaults);
	}

	/**
     * Retrieve a request payload item from the request.
     *
     * @param  string  key
     * @param  string|array|null  default
     *
     * @return string|array
     */
	T post(T = string)(string key, T v = T.init) {

		implementationMissing(false);
		// auto form = postForm();
		// if (form is null)
		// 	return v;
		// auto _v = postForm.getFromValue(key);
		// if (_v.length)
		// {
		// 	return to!T(_v);
		// }
		return v;
	}

	// CookieManager cookieManager()
	// {
	// 	if (_cookieManager is null)
	// 	{
	// 		_cookieManager = new CookieManager(header(HttpHeader.COOKIE));
	// 	}

	// 	return _cookieManager;
	// }

	/**
     * Determine if a cookie is set on the request.
     *
     * @param  string  key
     * @return bool
     */
	// bool hasCookie(string key)
	// {
	// 	// return cookie(key).length > 0;
	// 	foreach(Cookie c; _cookies) {
	// 		if(c.getName == key)
	// 			return true;
	// 	}
	// 	return false;
	// }

	// bool hasCookie()
	// {
	// 	return _cookies.length > 0;
	// }

	/**
     * Retrieve a cookie from the request.
     *
     * @param  string  key
     * @param  string|array|null  default
     * @return string|array
     */
	string cookie(string key, string defaultValue = null) {
		// return cookieManager.get(key, defaultValue);
		foreach (Cookie c; getCookies()) {
			if (c.getName == key)
				return c.getValue();
		}
		return defaultValue;
	}

	Cookie[] getCookies() {
		if (_cookies is null) {
			Array!(Cookie) list;
			foreach (string v; getFields().getValuesList(HttpHeader.COOKIE)) {
				if (v.empty)
					continue;
				foreach (Cookie c; CookieParser.parseCookie(v))
					list.insertBack(c);
			}
			_cookies = list.array();
		}
		return _cookies;
	}

	/**
     * Get an array of all cookies.
     *
     * @return array
	 */
	// string[string] cookie()
	// {
	// 	// return cookieManager.requestCookies();

	// 	implementationMissing(false);
	// 	return null;
	// }

	/**
     * Get an array of all of the files on the request.
     *
     * @return array
     */
	// HttpForm.FormFile[string] allFiles()
	// {
	// 	return httpForm.fileMap();
	// }

	/**
     * Determine if the uploaded data contains a file.
     *
     * @param  string  key
     * @return bool
     */
	// public bool hasFile(string key)
	// {
	// 	HttpForm.FormFile file = httpForm.getFileValue(key);

	// 	return file !is null;
	// }

	/**
     * Retrieve a file from the request.
     *
     * @param  string  key
     * @param  mixed default
     * @return HttpForm.FormFile
     */
	// HttpForm.FormFile file(string key)
	// {
	// 	return httpForm.getFileValue(key);
	// }

	@property string method() {
		return _request.getMethod();
	}

	@property string url() {
		return _request.getURIString();
	}

	// @property string fullUrl()
	// {
	// 	return _httpMessage.url();
	// }

	// @property string fullUrlWithQuery()
	// {
	// 	return _httpMessage.url();
	// }

	@property string path() {
		return _request.getURI().getPath();
	}

	@property string decodedPath() {
		return _request.getURI().getDecodedPath();
	}

	/**
     * Gets the request's scheme.
     *
     * @return string
     */
	public string getScheme() {
		return isSecure() ? "https" : "http";
	}

	/**
     * Get a segment from the URI (1 based index).
     *
     * @param  int  index
     * @param  string|null  default
     * @return string|null
     */
	string segment(int index, string defaults = null) {
		string[] s = segments();
		if (s.length <= index || index <= 0)
			return defaults;
		return s[index - 1];
	}

	/**
     * Get all of the segments for the request path.
     *
     * @return array
     */
	string[] segments() {
		string[] t = decodedPath().split("/");
		string[] r;
		foreach (string v; t) {
			if (!v.empty)
				r ~= v;
		}
		return r;
	}

	/**
     * Determine if the current request URI matches a pattern.
     *
     * @param  patterns
     * @return bool
     */
	bool uriIs(string[] patterns...) {
		string path = decodedPath();

		foreach (string pattern; patterns) {
			auto s = matchAll(path, regex(pattern));
			if (!s.empty)
				return true;
		}
		return false;
	}

	/**
     * Determine if the route name matches a given pattern.
     *
     * @param  dynamic  patterns
     * @return bool
     */
	bool routeIs(string[] patterns...) {
		if (_route !is null) {
			string r = _route.getRoute();
			foreach (string pattern; patterns) {
				auto s = matchAll(r, regex(pattern));
				if (!s.empty)
					return true;
			}
		}
		return false;
	}

	/**
     * Determine if the current request URL and query string matches a pattern.
     *
     * @param  dynamic  patterns
     * @return bool
     */
	// bool fullUrlIs(string[] patterns...)
	// {
	// 	string r = this.fullUrl();
	// 	foreach (string pattern; patterns)
	// 	{
	// 		auto s = matchAll(r, regex(pattern));
	// 		if (!s.empty)
	// 			return true;
	// 	}

	// 	return false;
	// }

	/**
     * Determine if the request is the result of an AJAX call.
     *
     * @return bool
     */
	@property bool ajax() {
		return getFields().get("X-Requested-With") == "XMLHttpRequest";
	}

	/**
     * Determine if the request is the result of an PJAX call.
     *
     * @return bool
     */
	@property bool pjax() {
		return getFields().containsKey("X-PJAX");
	}

	/**
     * Determine if the request is over HTTPS.
     *
     * @return bool
     */
	@property bool secure() {
		return isSecure();
	}

	/**
     * Checks whether the request is secure or not.
     *
     * This method can read the client protocol from the "X-Forwarded-Proto" header
     * when trusted proxies were set via "setTrustedProxies()".
     *
     * The "X-Forwarded-Proto" header must contain the protocol: "https" or "http".
     *
     * @return bool
     */
	@property bool isSecure() {
		throw new NotImplementedException("isSecure");
	}

	/**
     * Get the client IP address.
     *
     * @return string
     */
	// @property string ip()
	// {
	// 	return _httpMessage.getClientIP();
	// }

	/**
     * Get the client IP addresses.
     *
     * @return array
     */
	// @property string[] ips()
	// {
	// 	throw new NotImplementedException("ips");
	// }

	/**
     * Get the client user agent.
     *
     * @return string
     */
	@property string userAgent() {
		return getFields().get("User-Agent");
	}

	// Request merge(string[] input)
	// {
	// 	string[string] inputSource = getInputSource;
	// 	for (size_t i = 0; i < input.length; i++)
	// 	{
	// 		inputSource[to!string(i)] = input[i];
	// 	}
	// 	return this;
	// }

	/**
     * Replace the input for the current request.
     *
     * @param  array input
     * @return Request
     */
	// Request replace(string[string] input)
	// {
	// 	if (isContained(this.method, ["GET", "HEAD"]))
	// 		_httpMessage.queryParam = input;
	// 	else
	// 	{
	// 		httpForm.formData = input;
	// 	}

	// 	return this;
	// }

	// JSONValue json(string key, string defaults = null)
	// {
	// 	string content = cast(string) ubyteBody();

	// 	return parseJSON(content);
	// }

	protected string[string] getInputSource() {
		implementationMissing(false);
		return null;
		// if (isContained(this.method, ["GET", "HEAD"]))
		// 	return _httpMessage.queryParam();
		// else
		// {
		// 	return httpForm.formData();
		// }
	}

	/**
     * Get the user making the request.
     *
     * @param  string|null guard
     * @return User
     */
	@property User user() {
		return this._user;
	}

	// ditto
	@property void user(User user) {
		this._user = user;
	}

	/**
     * Get the route handling the request.
     *
     * @param  string|null param
     *
     * @return Route
     */
	@property Route route() {
		return _route;
	}

	// ditto
	@property void route(Route value) {
		_route = value;
	}

	/**
     * Get a unique fingerprint for the request / route / IP address.
     *
     * @return string
     */
	// string fingerprint()
	// {
	// 	if(_route is null)
	// 		throw new Exception("Unable to generate fingerprint. Route unavailable.");

	// 	string[] r ;
	// 	foreach(HTTP_METHODS m;  _route.getMethods())
	// 		r ~= to!string(m);
	// 	r ~= _route.getUrlTemplate();
	// 	r ~= this.ip();

	// 	return toHexString(sha1Of(join(r, "|"))).idup;
	// }

	/**
     * Set the JSON payload for the request.
     *
     * @param json
     * @returnthis
     */
	Request setJson(string[string] json) {
		_json = JSONValue(json);
		return this;
	}

	/**
     * Get the user resolver callback.
     *
     * @return Closure
     */
	Closure getUserResolver() {
		if (userResolver is null)
			return (Request) {  };

		return userResolver;
	}

	/**
     * Set the user resolver callback.
     *
     * @param  Closure callback
     * @returnthis
     */
	Request setUserResolver(Closure callback) {
		userResolver = callback;
		return this;
	}

	/**
     * Get the route resolver callback.
     *
     * @return Closure
     */
	public Closure getRouteResolver() {
		if (routeResolver is null)
			return (Request) {  };

		return routeResolver;
	}

	/**
     * Set the route resolver callback.
     *
     * @param  Closure callback
     * @returnthis
     */
	Request setRouteResolver(Closure callback) {
		routeResolver = callback;
		return this;
	}

	/**
     * Get all of the input and files for the request.
     *
     * @return array
     */
	string[string] toArray() {
		return this.all();
	}

	/**
     * Determine if the given offset exists.
     *
     * @param  string offset
     * @return bool
     */
	bool offsetExists(string offset) {
		string[string] a = this.all();
		string* p = (offset in a);

		if (p is null)
			return this.route.hasParameter(offset);
		else
			return true;

	}

	string offsetGet(string offset) {
		return __get(offset);
	}

	/**
     * Set the value at the given offset.
     *
     * @param  string offset
     * @param  mixed value
     * @return void
     */
	void offsetSet(string offset, string value) {
		string[string] dict = this.getInputSource();
		dict[offset] = value;
	}

	/**
     * Remove the value at the given offset.
     *
     * @param  string offset
     * @return void
     */
	void offsetUnset(string offset) {
		string[string] dict = this.getInputSource();
		dict.remove(offset);
	}

	/**
     * Check if an input element is set on the request.
     *
     * @param  string  key
     * @return bool
     */
	protected bool __isset(string key) {
		string v = __get(key);
		return !v.empty;
	}

	/**
     * Get an input element from the request.
     *
     * @param  string  key
     * @return string
     */
	protected string __get(string key) {
		string[string] a = this.all();
		string* p = (key in a);

		if (p is null) {
			return this.route.getParameter(key);
		}
		else
			return *p;
	}

	/**
     * Returns the protocol version.
     *
     * If the application is behind a proxy, the protocol version used in the
     * requests between the client and the proxy and between the proxy and the
     * server might be different. This returns the former (from the "Via" header)
     * if the proxy is trusted (see "setTrustedProxies()"), otherwise it returns
     * the latter (from the "SERVER_PROTOCOL" server parameter).
     *
     * @return string
     */
	string getProtocolVersion() {
		return _request.getHttpVersion().toString();
	}

	/**
     * Indicates whether this request originated from a trusted proxy.
     *
     * This can be useful to determine whether or not to trust the
     * contents of a proxy-specific header.
     *
     * @return bool true if the request came from a trusted proxy, false otherwise
     */
	bool isFromTrustedProxy() {
		implementationMissing(false);
		return false;
	}

private:
	User _user;
	Route _route;
	string _stringBody;
	string[string] _mate;
	// CookieManager _cookieManager;
	JSONValue _json;
	uint _maxBodySize;
	string _action;
}

void setTrustedProxies(string[] proxies, int headerSet) {
	trustedProxies = proxies;
	trustedHeaderSet = headerSet;
}

package {
	string[][string] formats;
	string[] trustedProxies;
	int trustedHeaderSet;

	const HEADER_FORWARDED = 0b00001; // When using RFC 7239
	const HEADER_X_FORWARDED_FOR = 0b00010;
	const HEADER_X_FORWARDED_HOST = 0b00100;
	const HEADER_X_FORWARDED_PROTO = 0b01000;
	const HEADER_X_FORWARDED_PORT = 0b10000;
	const HEADER_X_FORWARDED_ALL = 0b11110; // All "X-Forwarded-*" headers
	const HEADER_X_FORWARDED_AWS_ELB = 0b11010; // AWS ELB doesn"t send X-Forwarded-Host	
}

static this() {
	formats["html"] = ["text/html", "application/xhtml+xml"];
	formats["txt"] = ["text/plain"];
	formats["js"] = ["application/javascript", "application/x-javascript", "text/javascript"];
	formats["css"] = ["text/css"];
	formats["json"] = ["application/json", "application/x-json"];
	formats["jsonld"] = ["application/ld+json"];
	formats["xml"] = ["text/xml", "application/xml", "application/x-xml"];
	formats["rdf"] = ["application/rdf+xml"];
	formats["atom"] = ["application/atom+xml"];
	formats["rss"] = ["application/rss+xml"];
	formats["form"] = ["application/x-www-form-urlencoded"];
}

private Request _request;

Request request() {
	return _request;
}

void request(Request request) {
	_request = request;
}


// HttpSession session()
// {
// 	return request().session();
// }

// string session(string key)
// {
// 	return session().attributes.get(key);
// }

// void session(string[string] values)
// {
// 	foreach (key, value; values)
// 	{
// 		session().put(key, value);
// 	}
// }