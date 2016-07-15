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

public import hunt.http.response;
public import hunt.http.request;
public import hunt.router.middleware;

public import hunt.application.middleware;

import std.traits;

struct action{}

struct middleware{
	string className;
}

T instanceOf (T) (Object value)
{
	return cast(T) (value);
}

interface IController
{
	bool __CALLACTION__(string method,RouterPipelineContext contex, Request req,  Response res);

	IMiddleware[] getMiddleware();
}

class Controller : IController
{
	protected
	{
		Request request;
		Response response;
		RouterPipelineContext context;
		///called before all actions
		IMiddleware[] middlewares;

	}
	bool __CALLACTION__(string method,RouterPipelineContext contex, Request req,  Response res)
	{
		return false;
	}
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
}

alias MakeController = HuntDynamicCallFun;

mixin template HuntDynamicCallFun()
{
	import std.traits;
	enum str = _createCallActionFun!(typeof(this));
	//pragma(msg, "call fun generate in ..." ~ (fullyQualifiedName!(typeof(this))));
	//pragma(msg, str);
	mixin(str);
}

string  _createCallActionFun(T)()
{
    import std.traits;
	import std.format;
	string str = "override bool __CALLACTION__(string funName,RouterPipelineContext context,Request req,  Response res) {";
	str ~= "import std.experimental.logger;import std.variant;import std.conv;";
	str ~= "trace(\"call function \", funName);";
	str ~= "this.request = req; this.response = res; this.context = context;";
    str ~= "switch(funName){";
    foreach(memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
        {
            foreach (t;__traits(getOverloads,T,memberName)) 
            {
				static if(!hasUDA!(t, action))
				{
					continue;
				}
				else
				{
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
    }
	str ~= "default : break;}";

	str ~= "return false;";
    str ~= "}";
    return str;
}
