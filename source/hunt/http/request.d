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
module hunt.http.request;

import std.exception;

import collie.buffer;
import collie.codec.http;
import collie.codec.http.server.requesthandler;
import collie.codec.http.server.httpform;

import hunt.http.response;
import hunt.http.session;
import hunt.http.sessionstorage;
import hunt.http.cookie;

import std.string;

alias CreatorBuffer = Buffer delegate();
alias DoHandler = void function(Request) nothrow;

final class Request : RequestHandler
{
	this(CreatorBuffer cuffer,DoHandler handler)
	{
		_creatorBuffer = cuffer;
		_handler = handler;
	}

	@property HTTPForm postForm()
	{
		if (_body && ( _form is null))
			_form = new HTTPForm(_req);
		return _form;
	}

	@property Header(){return _headers;}

	@property Body(){return _body;}

	@property mate(){return _mate;}

	@property path(){return Header.getPath;}

	@property method(){return Header.methodString;}

	@property host(){return header(HTTPHeaderCode.HOST);}

	string header(HTTPHeaderCode code){
		_headers.getHeaders.getSingleOrEmpty(code);
	}

	string header(string key){
		_headers.getHeaders.getSingleOrEmpty(key);
	}

	bool headerExists(HTTPHeaderCode code){
		_headers.getHeaders.exists(code);
	}

	bool headerExists(string key){
		_headers.getHeaders.exists(code);
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

	string getMate(string key)
	{
		return _mate.get(key, "");
	}

	void addMate(string key, string value)
	{
		_mate[key] = value;
	}

	SessionInterface getSession( S = Session)(string sessionName = "hunt_session", SessionStorageInterface t =  newStorage()) //if()
	{
		auto co = getCookie(sessionName);
		if (co is null) return new S(t);
		return new S(co.value, t);
	}

	private Cookie getCookie(string key)
	{
		if(cookies.length == 0)
		{
			string cookie = header(HTTPHeaderCode.COOKIE);
			cookies = parseCookie(cookie);
		}
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
		_headers.queryParam();
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

	@property ref string[string] materef() {return _mate;}

	Response createResponse()
	{
		if(_error != HTTPErrorCode.NO_ERROR)
			return null;
		if(_res is null)
			_res = new Response(_downstream);
		return _res;
	}
protected:
	override void onBody(const ubyte[] data) nothrow {
		collectException((){
				if(_body is null){
					_body = _creatorBuffer();
				}
				_body.write(data);
			});
	}

	override void onEOM() nothrow {
		_handler();
	}

	override void requestComplete() nothrow {
		collectException((){
				_error = HTTPErrorCode.STREAM_CLOSED;
				import collie.utils.memory;
				if(_headers)gcFree(_headers);
				if(_res)gcFree(_res);
			}());
	}

	override void onResquest(HTTPMessage headers) nothrow {
		_headers = headers;
	}

	override void onError(HTTPErrorCode code) nothrow {
		collectException((){
				if(_res)_res.clear();
				_error = code;
				if(error == HTTPErrorCode.TIME_OUT){
					// send 502;
				}
			}());
	}

private:
	string[string] _mate;
	//SessionInterface session;
	Cookie[string] cookies;
	Buffer _body;
	HTTPMessage _headers;
	Response _res;
	HTTPErrorCode _error = HTTPErrorCode.NO_ERROR;
	CreatorBuffer _creatorBuffer;
	DoHandler _handler;
}
