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
module hunt.application.controller;

import std.experimental.logger;

public import hunt.view;
public import hunt.http.response;
public import hunt.http.request;
public import hunt.router;
import hunt.router.router;


public import hunt.application.middleware;

import std.traits;

enum Action;

struct Middleware{
	string className;
}


abstract class Controller
{
	protected
	{
		Request request;
		///called before all actions
		IMiddleware[] middlewares;
		View _view;

	}
	final @property response(){
		return request.createResponse();
	}
	/// called before action  return true is continue false is finish
	bool before(){return true;}
	/// called after action  return true is continue false is finish
	bool after(){return true;}

	///add middleware
	///return true is ok, the named middleware is already exist return false
	bool addMiddleware(IMiddleware midw)
	{
		if(midw is null) return false;
		foreach(tmp; this.middlewares)
		{
			if(tmp.name == midw.name)
			{
				return false;
			}
		}
		this.middlewares ~= midw;
		return true;
	}
	///add middleware
	IMiddleware[] getMiddleware()
	{
		return this.middlewares;
	}

	//view render
	@property View view()
	{
		if(_view is null)
		{
			_view = new View();
		}
		return _view;
	}

	void render(string filename = null)()
	{
		this.response.html(this.view.render!filename());
	}

	void show(string filename = null)()
	{
		this.response.html(this.view.show!filename());
	}

	protected final bool __handleWares()
	{
		foreach(ws;middlewares){
			if(!ws.onProcess(request,response())){
				return false;
			}
		}
		return true;
	}
}

mixin template MakeController(string moduleName = __MODULE__)
{
	mixin HuntDynamicCallFun!(typeof(this),moduleName);
}

mixin template HuntDynamicCallFun(T,string moduleName)
{
public:
	mixin(__createCallActionFun!(T,moduleName));
	shared static this(){
		import hunt.router.build;
		mixin(__creteRouteMap!(T,moduleName));
		mixin(_createRouterCallRouteFun!(T,true)());
	}
}

string  __createCallActionFun(T, string moduleName)()
{
	import std.traits;
	import std.format;
	string str = "bool __CALLACTION__(string funName,Request req) {";
	str ~= "\n\tauto ptr = this; ptr.request = req;";
	str ~= "\n\tif(!ptr.__handleWares()) return false;trace(\"------------------\");";
	str ~= "\n\t switch(funName){";
	foreach(memberName; __traits(allMembers, T))
	{
		static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
		{
			foreach (t;__traits(getOverloads,T,memberName)) 
			{
				//alias pars = ParameterTypeTuple!(t);
				static if(/*ParameterTypeTuple!(t).length == 0 && */( hasUDA!(t, Action) || hasUDA!(t, Route))) {
					str ~= "case \"";
					str ~= memberName;
					str ~= "\": {\n";
					static if(hasUDA!(t, Action)){
						enum ws = getUDAs!(t, Middleware);
						static if(ws.length)
						{
							foreach(i,w; ws)
							{
								str ~= format(q{ 
										scope auto wb_%s_%s = new %s();
										trace("do middler");
										if(!wb_%s_%s.onProcess(ptr.request, ptr.response)){return false;}
									}, i,memberName, w.className, i, memberName);
							}

						}

						//before
						str ~= q{
							trace("do funnnn---------before---------");
							if(!ptr.before()){return false;}
							trace("do funnnn---------");
						};
					}
					//action
					str ~= "ptr." ~ memberName ~ "();";
					static if(hasUDA!(t, Action)){
						//after
						str ~= q{
							if(!ptr.after()){return false;}
						};
					}
					str ~= "}\n break;";
				}
			}
		}
	}
	str ~= "default : break;}";

	str ~= "return false;";
	str ~= "}";
	return str;
}

string  __creteRouteMap(T, string moduleName)()
{
	string str = "";
	foreach(memberName; __traits(allMembers, T)){
		static if (is(typeof(__traits(getMember,  T, memberName)) == function) ){
			foreach (t;__traits(getOverloads,T,memberName)) {
				static if(/*ParameterTypeTuple!(t).length == 0 && */ hasUDA!(t, Action) ){
					str ~= "\n\taddRouteList(\"" ~ moduleName ~ "." ~ T.stringof ~ "." ~ memberName  ~ "\",&callHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
				}
			}
		}
	}
	return str;
}

RouterHandler.HandleFunction getRouteFormList(string str){
	if(!_init) _init = true;
	trace("get router : ", str);
	return __routerList.get(str,null);
}

void addRouteList(string str, RouterHandler.HandleFunction fun)
{
	if(!_init){
		trace("addRouteList : ", str);
		__routerList[str] = fun;
	}
}

private:
__gshared bool _init = false;
__gshared RouterHandler.HandleFunction[string]  __routerList;

/*
static bool __STATIC_CALLACTION__(typeof(this) ptr,string funName,Request req) {
	import std.experimental.logger;
	import std.variant;
	import std.conv;import app.controller.index;
	auto action = cast(IndexController)ptr;
	trace("action is null? ", (action is null), "  funName is: ", funName);
	if(!action) return false;
	if(!action.__handleWares()) return false;
	trace("------------------"); switch(funName){
		case "show": {
			scope auto wb_0_show = new BeforeMiddleware();
			if(!wb_0_show.onProcess(action.request, action.response)){return false;}
			
			scope auto wb_1_show = new AfterMiddleware();
			if(!wb_1_show.onProcess(action.request, action.response)){return false;}
			
			if(!action.before()){return false;}
			action.show();
			if(!action.after()){return false;}
		}
			break;
		case "list": {
			
			scope auto wb_0_list = new OneMiddleware();
			if(!wb_0_list.onProcess(action.request, action.response)){return false;}
			
			if(!action.before()){return false;}
			action.list();
			if(!action.after()){return false;}
		}
			break;
		case "index": {
			
			if(!action.before()){return false;}
			action.index();
			if(!action.after()){return false;}
		}
			break;
		case "showbool": {
			
			if(!action.before()){return false;}
			action.showbool();
			if(!action.after()){return false;}
		}
		break;default : break;}
	return false;
}
*/
