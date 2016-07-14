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
public import hunt.router.middleware;
import std.traits;

struct action{}

struct widget{
	string before;
	string after;
}
/**
 * Checks if a member is has widget, and returns the widget .
 **/
static widget getWidget(alias member)() {
	enum ws = getUDAs!(member, widget);
	static if(ws.length)
	{
		return ws[0];
	}
	else
	{
		return cast(widget)null;
	}
}


T instanceOf (T) (Object value)
{
	return cast(T) (value);
}

interface IController
{
	bool __CALLACTION__(string method,RouterPipelineContext contex, Request req,  Response res);
}

class Controller : IController
{
	protected
	{
		Request request;
		Response response;
		RouterPipelineContext context;
	}
	bool __CALLACTION__(string method,RouterPipelineContext contex, Request req,  Response res)
	{
		return false;
	}
}

alias ControllerInCompileTime = HuntDynamicCallFun;

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
					enum w = getWidget!t ;
					static if(w.before !is null && w.before != "")
					{
						str ~= format(q{ 
							auto wb_%s = new %s();
							auto wretb_%s = wb_%s.handle(this.request, this.response);
							if(!wretb_%s){return false;}
							}, memberName, w.before, memberName, memberName, memberName);
					}
					str ~= memberName ~ "();";
					static if( w.after !is null && w.after != "")
					{
						str ~= format(q{
							auto waf_%s = new %s();
							auto wretf_%s = waf_%s.handle(this.request, this.response);
							if(!wretf_%s){return false;}
							},memberName, w.after, memberName, memberName, memberName);
					}
					str ~= "break;";
				}
                /*Parameters!(t) functionArguments;
                static if(functionArguments.length == 2 && is(typeof(functionArguments[0]) == Request) && is(typeof(functionArguments[1]) == Response))
                {
                    str ~= "case \"";
                    str ~= memberName;
                    str ~= "\":";
					str = str ~  memberName ~ "(); context.next(req,res);return true;";
                }
				static if(functionArguments.length == 3 && is(typeof(functionArguments[0]) == RouterPipelineContext)
					is(typeof(functionArguments[1]) == Request) && is(typeof(functionArguments[0]) == Response))
				{
					str ~= "case \"";
					str ~= memberName;
					str ~= "\":";
					str = str ~  memberName ~ "();return true;";
				}*/
            }
        }
    }
	str ~= "default : break;}";

	str ~= "return false;";
    str ~= "}";
    return str;
}
