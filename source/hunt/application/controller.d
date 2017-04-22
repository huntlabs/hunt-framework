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
 
module hunt.application.controller;

import std.experimental.logger;

public import hunt.view;
public import hunt.http.response;
public import hunt.http.request;
public import hunt.router;
public import hunt.application.middleware;

import std.exception;
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

	final @property session()
	{
		return request.getSession();
	}
	
	final @property response()
	{
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
		foreach(ws;middlewares)
		{
			if(!ws.onProcess(request,response()))
			{
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
	shared static this()
    {
		mixin(__creteRouteMap!(T,moduleName));
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
		static if (is(typeof(__traits(getMember, T, memberName)) == function))
		{
			foreach (t;__traits(getOverloads, T, memberName))
			{
				static if (/*ParameterTypeTuple!(t).length == 0 && */ hasUDA!(t, Action))
				{
					str ~= "\n\taddRouteList(\"" ~ moduleName ~ "." ~ T.stringof ~ "." ~ memberName  ~ "\",&callHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
				}
			}
		}
	}
	return str;
}

void callHandler(T, string fun)(Request req) if(is(T == class) || is(T == struct) && hasMember!(T,"__CALLACTION__"))
{
    T handler = new T();
    if(!handler.__CALLACTION__(fun,req))
    {
        Response res;
        collectException(req.createResponse(),res);
        
        if(res)
            res.done();
    }
}

HandleFunction getRouteFormList(string str)
{
	if (!_init)
	{
		_init = true;
	}

	return __routerList.get(str, null);
}

void addRouteList(string str, HandleFunction fun)
{
    trace("add str is .... ", str);
	if(!_init)
	{
		import std.string : toLower;

		__routerList[str.toLower] = fun;
	}
}

private:
__gshared bool _init = false;
__gshared HandleFunction[string]  __routerList;
