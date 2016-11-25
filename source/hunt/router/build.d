module hunt.router.build;

import hunt.http.request;
import hunt.http.response;
import collie.utils.functional;
import hunt.router.routergroup;

import std.traits;
import std.exception;

struct Action
{
	this(string dom, string pa){
		domain = dom;
		path = path;
	}
	this(string pa){
		path = pa;
	}

	string domain;
	string path;
}

mixin template BuildRouterFunction(T, bool controller = false) if(is(T == class) || is(T == struct) /*|| is(T == module)*/)
{
	shared static this(){
		import std.experimental.logger;
		import std.conv;
		import hunt.router.build;
		mixin(_createCallActionFun!(T,controller)());
	}
}

string  _createCallActionFun(T, bool controller)()
{
	string str = "";
	
	foreach(memberName; __traits(allMembers, T))
	{
		static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
		{
			foreach (t;__traits(getOverloads,T,memberName)) 
			{
				static if(!hasUDA!(t, Action) || !TisPublic!(t))
					continue;

				static if(!controller && !TisPublic!(t))
					continue;

				Action action = getUDAs!(t, Action)[0];
				if(action.path.length == 0){
					continue;
				}
				alias ptype = Parameters!(t);
				static if(ptype.length != 1 || !is(ptype[0] == Request))
					continue;

				static if(controller){
					str ~= "\t\tdefaultRouter.addRoute(\"" ~ action.domain ~"\",\""~ path ~ "\",&doHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
				} else {
					str ~= "\t\tdefaultRouter.addRoute(\"" ~ action.domain ~"\",\""~ path ~ "\",bind(&callHandler!(" ~ T.stringof ~ "),\"" ~ memberName ~ "\");\n";
				}
			}
		}
	}
	return str;
}

void doHandler(T,string fun)(Request req) if(is(T == class) || is(T == struct))
{
	auto handler = new T();
	mixin("handler." ~ fun ~ "(req);");
}

void callHandler(T)(string fun,Request req) if(is(T == class) || is(T == struct) && hasMember!(T,"__CALLACTION__"))
{
	auto handler = new T();
	if(!handler.__CALLACTION__(fun,req))
	{
		Response res;
		collectException(req.createResponse(),res);
		if(res)
			res.done();
	}
}

template TisPublic(alias T)
{
	enum protection =  __traits(getProtection,T);
	enum TisPublic = (protection == "public");
}