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

public import hunt.view;
public import hunt.http.response;
public import hunt.http.request;
public import hunt.router;

public import hunt.application.middleware;

import std.traits;

struct middleware{
	string className;
}

auto instanceOf (T) (Object value)
{
	return cast(T) (value);
}

abstract class Controller : IController
{
	protected
	{
		Request request;
		///called before all actions
		IMiddleware[] middlewares;
		View _view;

	}
	bool __CALLACTION__(string method,Request req);

	/// called before action  return true is continue false is finish
	bool before(){return true;}
	/// called after action  return true is continue false is finish
	bool after(){return true;}

	///add middleware
	///return true is ok, the named middleware is already exist return false
	bool addMiddleware(IMiddleware midw)
	{
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
}

alias MakeController = HuntDynamicCallFun;

mixin template HuntDynamicCallFun()
{
public:
	mixin(_createCallActionFun!(typeof(this)));
	mixin BuildRouterFunction!(typeof(this),true);

}

string  _createCallActionFun(T)()
{
    import std.traits;
	import std.format;
	string str = "override bool __CALLACTION__(string funName,Request req) {";
	str ~= "import std.experimental.logger;import std.variant;import std.conv;";
	// str ~= "trace(\"call function \", funName);";
	str ~= "this.request = req; this.response = res;";
    str ~= "switch(funName){";
    foreach(memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
        {
            foreach (t;__traits(getOverloads,T,memberName)) 
            {
				static if(!hasUDA!(t, Action))
				{
					continue;
				}
				str ~= "case \"";
				str ~= memberName;
				str ~= "\":";
				enum ws = getUDAs!(t, middleware);
				static if(ws.length)
				{
					foreach(i,w; ws)
					{
						str ~= format(q{ 
								auto wb_%s_%s = new %s();
								if(!wb_%s_%s.onProcess(this.request, this.response)){return false;}
							}, i,memberName, w.className, i, memberName);
					}

				}

				//before
				str ~= q{
					if(!this.before()){return false;}
				};
				//action
				str ~= memberName ~ "();";
				//after
				str ~= q{
					if(!this.after()){return false;}
				};
				str ~= "break;";
            }
        }
    }
	str ~= "default : break;}";

	str ~= "return false;";
    str ~= "}";
    return str;
}
