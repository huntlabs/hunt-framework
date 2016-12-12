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
module hunt.router.router;

import std.regex;
import std.string;
import std.experimental.logger;

import hunt.router.utils;
import hunt.http.request;
import hunt.http.response;
import std.exception;

enum RouterHandlerType
{
	Delegate,
	Function,
	Null
}

struct RouterHandler
{
	alias HandleDelegate = void delegate(Request);
	alias HandleFunction = void function(Request);
	@property type(){
		return _type;
	}
	@property dgate(){
		return _dgate;
	}
	@property func(){
		return _func;
	}
private:
	RouterHandlerType _type = RouterHandlerType.Null;
	HandleDelegate _dgate;
	HandleFunction _func;
}

struct MachData
{
	RouterHandler * macth;
	string[string] mate;
}
/**
    The Router Class, Save and Macth the rule, and generte the Pipeline.
*/
final class Router
{
	alias HandleDelegate = RouterHandler.HandleDelegate;
	alias HandleFunction = RouterHandler.HandleFunction;
	this()
	{
		setDefaultRoute(&doDefault);
	}

	static void doDefault(Request req){
		Response res;
		collectException(req.createResponse(),res);
		if(!res) return;
		res.setHttpStatusCode(404).connectionClose();
		res.setContext("<H1>404! No Found<H1>");
		res.done();
	}

	void setDefaultRoute(HandleDelegate dohandle)
	{
		_handler._type = RouterHandlerType.Delegate;
		_handler._dgate = dohandle;
	}

	void setDefaultRoute(HandleFunction dohandle)
	{
		_handler._type = RouterHandlerType.Function;
		_handler._func = dohandle;
	}

	/**
        Add a Router rule. if config is done, will always erro.
        Params:
            method =  the HTTP method. 
            path   =  the request path.
            handle =  the delegate that handle the request.
            before =  The PipelineFactory that create the middleware list for the router rules, before  the router rule's handled execute.
            after  =  The PipelineFactory that create the middleware list for the router rules, after  the router rule's handled execute.
        Returns: the rule's element class. if can not add the rule will return null.
    */
	RouteElement addRoute(T)(string method, string path,T handle) if(is(T == HandleDelegate) || is(T == HandleFunction))
	{
		if (condigDone || method.length == 0 || path.length == 0 || handle is null)
			return null;
		method = toUpper(method);
		RouteMap map = _map.get(method, null);
		if (!map)
		{
			map = new RouteMap(this);
			_map[method] = map;
		}
		trace("add Router method: ", method);
		return map.add(path, handle);
	}

	/**
        Match the rule.if config is not done, will always erro.
        Params:
            method = the method group.
            path   = the path to match.
        Returns: 
            the pipeline has the Global MiddleWare ,Rule MiddleWare, Rule handler .
            the list is : Before Global MiddleWare -> Before Rule MiddleWare -> Rule handler -> After Rule MiddleWare -> After Global MiddleWare
            if don't match will  return null.
    */
	MachData match(string method, string path)
	{
		import std.stdio;
		trace("0---------------", method, "-------", path, "+++++++++");
		if (!condigDone)
			return MachData();
		RouteMap map = _map.get(method, null);
		if (!map)
			return MachData();
		return map.match(path);
	}
	/**
        get config is done.
        if config is done, the add rule will erro.
        else math rule will erro.
    */
	@property bool condigDone()
	{
		return _configDone;
	}
	
	/// set config done.
	void done()
	{
		_configDone = true;
	}
	
private:
	RouteMap[string] _map;
	bool _configDone = false;
	RouterHandler _handler;
}


/**
    A rule elment class.
*/
class RouteElement
{
	alias HandleDelegate = RouterHandler.HandleDelegate;
	alias HandleFunction = RouterHandler.HandleFunction;
	/**
        Constructor and set the path.
    */
	this(string path)
	{
		_path = path;
	}
	
	/// get the path
	final @property path() const
	{
		return _path;
	}
	
	/// get the handle.
	final @property handler() const
	{
		return _handler;
	}

	/// set the handle
	final sethandler(HandleDelegate handle)
	{
		_handler._dgate = handle;
		_handler._type = RouterHandlerType.Delegate;
	}

	final sethandler(HandleFunction handle)
	{
		_handler._func = handle;
		_handler._type = RouterHandlerType.Function;
	}
	
	MachData macth(string path)
	{
		MachData data;
		data.macth = &_handler;
		return data;
	}
	
private:
	string _path;
	RouterHandler _handler;
}

private:

final class RegexElement :RouteElement
{
	this(string path)
	{
		super(path);
	}
	
	override MachData macth(string path)
	{
		trace("the path is : ", path, "  \t\t regex is : ", _reg);
		auto rg = regex(_reg, "s");
		auto mt = matchFirst(path, rg);
		MachData data;
		if (mt)
		{
			data.macth = &_handler;
			foreach (attr; rg.namedCaptures)
			{
				data.mate[attr] = mt[attr];
			}

		}
		return data;
	}
	
private:
	bool setRegex(string reg)
	{
		if (reg.length == 0)
			return false;
		_reg = buildRegex(reg);
		if (_reg.length == 0)
			return false;
		return true;
	}
	
	string _reg;
}

final class RegexMap
{
	this(string path)
	{
		_path = path;
	}
	
	RouteElement add(RegexElement ele, string preg)
	{
		string rege;
		string str = getFirstPath(preg, rege);
		trace("RegexMap add : path = ", ele.path, " \n\tpreg = ", preg, "\n\t str = ", str,
		       "\n\t rege = ", rege, "\n");
		if (str.length == 0)
		{
			ele.destroy;
			return null;
		}
		if (isHaveRegex(str))
		{
			trace("set regex is  : ", preg);
			if (!ele.setRegex(preg))
				return null;
			
			bool isHas = false;
			for (int i = 0; i < _list.length; ++i) //添加的时候去重
			{
				if (_list[i].path == ele.path)
				{
					isHas = true;
					auto tele = _list[i];
					_list[i] = ele;
					tele.destroy;
				}
			}
			if (!isHas)
			{
				_list ~= ele;
			}
			return ele;
		}
		else
		{
			RegexMap map = _map.get(str, null);
			if (!map)
			{
				map = new RegexMap(str);
				_map[str] = map;
			}
			return map.add(ele, rege);
		}
	}
	
	MachData match(string path)
	{
		trace(" \t\tREGEX macth path:  ", path);
		MachData data;
		if (path.length == 0)
			return data;
		string lpath;
		string frist = getFirstPath(path, lpath);
		if (frist.length == 0)
			return data;
		auto map = _map.get(frist, null);
		trace("math frist: ", map);
		if (map)
		{
			data = map.match(lpath);
		}
		else
		{
			foreach (ele; _list)
			{
				data = ele.macth(path);
				if (data.macth !is null)
				{
					break;
				}
			}
		}
		return data;
	}
	
private:
	RegexMap[string] _map;
	RegexElement[] _list;
	string _path;
}

final class RouteMap
{
	alias HandleDelegate = RouterHandler.HandleDelegate;
	alias HandleFunction = RouterHandler.HandleFunction;
	
	this(Router router)
	{
		_router = router;
		_regexMap = new RegexMap("/");
	}

	RouteElement add(T)(string path, T handle) if(is(T == HandleDelegate) || is(T == HandleFunction))
	{
		if (isHaveRegex(path))
		{
			auto ele = new RegexElement(path);
			ele.sethandler(handle);
			return _regexMap.add(ele, path);
		}
		else
		{
			auto ele = new RouteElement(path);
			ele.sethandler(handle);
			_pathMap[path] = ele;
			return ele;
		}
	}
	
	MachData match(string path)
	{
		RouteElement element = _pathMap.get(path, null);
		if (!element){
			return _regexMap.match(path);
		} else {
			return element.macth(path);
		}
	}
	
private:
	Router _router;
	RouteElement[string] _pathMap;
	RegexMap _regexMap;
}