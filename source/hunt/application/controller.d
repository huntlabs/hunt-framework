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

mixin template HuntDynamicCallFun()
{
	mixin(_createCallActionFun!(typeof(this)));
}

string  _createCallActionFun(T)()
{
    import std.traits;
    import std.typecons;
	string str = "override bool __CALLACTION__(string funName,RouterPipelineContext context,Request req,  Response res) {";
	str ~= "import std.experimental.logger;";
	str ~= "trace(\"call function \", funName);";
	str ~= "this.request = req; this.response = res; this.context = context;";
    str ~= "switch(funName){";
    foreach(memberName; __traits(allMembers, T))
    {
        static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
        {
            foreach (t;__traits(getOverloads,T,memberName)) 
            {
				static if(memberName == "toString" || memberName == "toHash" || 
					memberName == "opCmp" ||memberName == "opEquals" ||memberName == "factory")
				{
					continue;
				}
				else
				{
					str ~= "case \"";
					str ~= memberName;
					str ~= "\":";
					str = str ~  memberName ~ "(); return true;";
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
    str ~= "default : return false;}";
    str ~= "}";
    return str;
}
