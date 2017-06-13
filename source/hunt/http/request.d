/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.http.request;

import std.exception;

import collie.buffer;
import collie.codec.http;
import collie.codec.http.server.requesthandler;
import collie.codec.http.server.httpform;
import collie.utils.memory;

import hunt.http.response;
import hunt.http.session;
import hunt.http.cookie;
import hunt.http.exception;
import hunt.http.nullbuffer;
import hunt.routing.route;
import hunt.utils.time;
import hunt.application.application;

import std.string;
import std.conv;

alias CreatorBuffer = Buffer delegate(HTTPMessage) nothrow;
alias DoHandler = void delegate(Request) nothrow;

final class Request : RequestHandler
{
	this(CreatorBuffer cuffer,DoHandler handler,uint maxsize = 8 * 1024 * 1024)
	{
		_creatorBuffer = cuffer;
		_handler = handler;
		_maxBodySize = maxsize;
	}

	@property HTTPForm postForm()
	{
		if (_body && ( _form is null))
			_form = new HTTPForm(header(HTTPHeaderCode.CONTENT_TYPE),_body);
		return _form;
	}

	@property Header(){return _headers;}

	@property Body(){
		if(_body)
			return _body; 
		else 
			return defaultBuffer;
	}

	@property route() { return _route; }
	@property void route(Route value) { _route = value; }

	@property mate(){return _mate;}

	@property path(){return Header.getPath;}

	@property method(){return Header.methodString;}

	@property host(){return header(HTTPHeaderCode.HOST);}

	string header(HTTPHeaderCode code){
		return _headers.getHeaders.getSingleOrEmpty(code);
	}

	string header(string key){
		return _headers.getHeaders.getSingleOrEmpty(key);
	}

	bool headerExists(HTTPHeaderCode code){
		return _headers.getHeaders.exists(code);
	}

	bool headerExists(string key){
		return _headers.getHeaders.exists(key);
	}

	int headersForeach(scope int delegate(string key, string value) each){
		return _headers.getHeaders.opApply(each);
	}

	int headersForeach(scope int delegate(HTTPHeaderCode code,string key, string value) each){
		return _headers.getHeaders.opApply(each);
	}

	bool headerValueForeach(string name,scope bool delegate(string value) func){
		return _headers.getHeaders.forEachValueOfHeader(name,func);
	}

	bool headerValueForeach(HTTPHeaderCode code,scope bool delegate(string value) func){
		return _headers.getHeaders.forEachValueOfHeader(code,func);
	}

	@property string clientIp()
	{
		string XFF = header("X-Forwarded-For");
		string[] xff_arr = split(XFF,", ");
		if(xff_arr.length > 0)
		{
			return xff_arr[0];
		}
		string XRealIP = header("X-Real-IP");
		if(XRealIP.length > 0)
		{
			return XRealIP;
		}
		return clientAddress.toAddrString();
	}
	@property string referer()
	{
		string rf = header("Referer");
		string[] rfarr = split(rf,", ");
		if(rfarr.length)
		{
			return rfarr[0];
		}
		return "";
	}
	@property clientAddress(){return _headers.clientAddress();}

	string getMate(string key,string value = null)
	{
		return _mate.get(key, value);
	}

	void addMate(string key, string value)
	{
		_mate[key] = value;
	}

	Session getSession(string sessionName = "hunt_session")
	{
		auto sessionId = getCookieValue(sessionName);
		if(!sessionId.length)
		{
			auto _tmp = new Session(Application.getInstance.sessionStorage);
			createResponse().setCookie(sessionName, _tmp.sessionId);
			return _tmp;
		}

		return new Session(sessionId,Application.getInstance.sessionStorage); 
	}

	@property Cookie[string] cookies()
	{
		if (_cookies.length == 0)
		{
			string cookie = header(HTTPHeaderCode.COOKIE);
			_cookies = parseCookie(cookie);
		}

		return _cookies;
	}
	
	private Cookie getCookie(string key)
	{
		return cookies.get(key,null);
	}

	string getCookieValue(string key)
	{
		auto cookie = this.getCookie(key);
		if(cookie is null)
		{
			return ""; 
		}
		return cookie.value;
	}

	///get queries
	@property string[string] queries()
	{
		return _headers.queryParam();
	}
	/// get a query
	T get(T = string)(string key, T v = T.init)
	{
		import std.conv;
		auto tmp = queries();
		if(tmp is null)
		{
			return v;   
		}
		auto _v = tmp.get(key, "");
		if(_v.length)
		{
			return to!T(_v);
		}
		return v;
	}

	/// get a post
	T post(T = string)(string key, T v = T.init)
	{
		import std.conv;
		auto form = postForm();
		if(form is null) return v;
		auto _v = postForm.getFromValue(key);
		if(_v.length)
		{
			return to!T(_v);
		}
		return v;
	}
	//	alias _req this;

	/// GET FILE
	auto file(T = string)(string key,T v = T.init)
	{
		return postForm.getFileValue(key);
	}

	@property ref string[string] materef() {return _mate;}

	Response createResponse()
	{
		if(_error != HTTPErrorCode.NO_ERROR)
			throw new CreateResponseException("http ero is : " ~ to!string(_error));
		if(_res is null) {
			_res = new Response(_downstream);
		}
		return _res;
	}
protected:
	override void onBody(const ubyte[] data) nothrow {
		collectException((){
				if(fristBody){
					_body = _creatorBuffer(_headers);
					fristBody = false;
					if(_body is null) {
						onError(HTTPErrorCode.FRAME_SIZE_ERROR);
						return;
					}
				}
				if(_body) {
					_body.write(data);
					if(_body.length > _maxBodySize){
						onError(HTTPErrorCode.FRAME_SIZE_ERROR);
						gcFree(_body);
						_body = null;
					}
				}
			}());
	}

	override void onEOM() nothrow {
		if(_error == HTTPErrorCode.NO_ERROR)
			_handler(this);
	}

	override void requestComplete() nothrow {
		collectException((){
				_error = HTTPErrorCode.STREAM_CLOSED;
				import collie.utils.memory;
				if(_body)gcFree(_body);
				if(_headers)gcFree(_headers);
				if(_res)gcFree(_res);
			}());
	}

	override void onResquest(HTTPMessage headers) nothrow {
		_headers = headers;
	}

	override void onError(HTTPErrorCode code) nothrow {
		collectException((){
				scope(exit) {
					if(_res)_res.clear();
					_downstream = null;
				}
				_error = code;
				if(_error == HTTPErrorCode.REMOTE_CLOSED)
					return;
				if(_res is null){
					_res = new Response(_downstream);
				}
				if(_error == HTTPErrorCode.TIME_OUT){
					_res.setHttpStatusCode(408);
				} else if(_error ==  HTTPErrorCode.FRAME_SIZE_ERROR){
					_res.setHttpStatusCode(429);
				} else {
					_res.setHttpStatusCode(502);
				}
				_res.done();
			}());
	}

private:
	Route _route;
	string[string] _mate;
	Cookie[string] _cookies;
	Buffer _body;
	HTTPMessage _headers;
	HTTPForm _form;
	Response _res;
	HTTPErrorCode _error = HTTPErrorCode.NO_ERROR;
	CreatorBuffer _creatorBuffer;
	uint _maxBodySize;
	DoHandler _handler;
	bool fristBody = true;
}
