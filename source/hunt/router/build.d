module hunt.router.build;

import hunt.http.request;
import hunt.http.response;
public import collie.utils.functional;
import hunt.router.routergroup;

import std.traits;
import std.exception;

struct Route
{
	this(string dom, string md,string pa){
		method = md;
		domain = dom;
		path = path;
	}
	this(string md,string pa){
		method = md;
		path = pa;
	}

	string domain;
	string method;
	string path;
}

mixin template BuildRouterFunction(T, bool controller = false) if(is(T == class) || is(T == struct) /*|| is(T == module)*/)
{
	shared static this(){
		import std.experimental.logger;
		import std.conv;
		import hunt.router.build;
		mixin(_createRouterCallRouteFun!(T,controller)());
	}
}

string  _createRouterCallRouteFun(T, bool controller)()
{
	string str = "";
	
	foreach(memberName; __traits(allMembers, T))
	{
		static if (is(typeof(__traits(getMember,  T, memberName)) == function) )
		{
			foreach (t;__traits(getOverloads,T,memberName)) 
			{
				static if(hasUDA!(t, Route) && (controller || TisPublic!(t))) {
					alias actions = getUDAs!(t, Route);
					static if(actions.length == 0) continue;

					Route action = actions[0];
					if(action.path.length > 0){
						alias ptype = Parameters!(t);
						static if(ptype.length == 1 && is(ptype[0] == Request)) {
							static if(!controller){
								str ~= "\t\taddRouteHelp(\"" ~ action.domain ~"\",\""~ action.method ~ "\",\""~ action.path ~ "\",&doHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
							} else {
								str ~= "\t\taddRouteHelp(\"" ~ action.domain ~"\",\""~ action.method ~ "\",&callHandler!(" ~ T.stringof ~ ",\"" ~ memberName ~ "\"));\n";
							}
						}
					}
				}
			}
		}
	}
	return str;
}

void addRouteHelp(Handler)(string domin, string method, string path,Handler t)
{
	import std.string;
	import hunt.router.configbase;

	if(method == "*"){
		method = fullMethod;
	} 
	string[]  methods = split(method,',');
	foreach(str;methods) {
		defaultRouter.addRoute(domin,strip(str),path,t);
	}
}

void doHandler(T,string fun)(Request req) if(is(T == class) || is(T == struct))
{
	auto handler = new T();
	mixin("handler." ~ fun ~ "(req);");
}


void callHandler(T,string fun)(Request req) if(is(T == class) || is(T == struct) && hasMember!(T,"__CALLACTION__"))
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