module hunt.router.routergroup;

import hunt.router.router;
import hunt.router.utils;

/**
    the router group.
*/
final class RouterGroup
{
	alias HandleDelegate = RouterHandler.HandleDelegate;
	alias HandleFunction = RouterHandler.HandleFunction;
	
	this()
	{
		_router = new  Router();
	}
	/**
        Add a Router in this Group;
        Params:
            domain = the domain. if the domain is exets, will override.
            router = the router will add.
    */
	void addRouter(string domain,Router router)
	{
		_routerList[domain] = router;
	}

	void setDefaultRoute(T)(string domain,T dohandle)if(is(T == HandleDelegate) || is(T == HandleFunction))
	{

		Router router;
		if(domain.length == 0){
			router = _router;
		} else {
			_routerList.get(domain,null);
			if(router is null)
			{
				router = new Router();
				_routerList[domain] = router;
			}
		}
		router.setDefaultRoute(dohandle);
	}
	/**
        Add a Router rule. if config is done, will always erro.
        Params:
            domain =  the domain group.
            method =  the HTTP method. 
            path   =  the request path.
            handle =  the delegate that handle the request.
            before =  The PipelineFactory that create the middleware list for the router rules, before  the router rule's handled execute.
            after  =  The PipelineFactory that create the middleware list for the router rules, after  the router rule's handled execute.
        Returns: the rule's element class. if can not add the rule will return null.
    */
	RouteElement addRoute(T)(string domain, string method,string path, T handle) if(is(T == HandleDelegate) || is(T == HandleFunction))
	{
		if(domain.length == 0)
		{
			return _router.addRoute(method,path,handle);
		} 
		
		
		auto router = _routerList.get(domain,null);
		if(router is null)
		{
			router = new Router();
			_routerList[domain] = router;
		}
		
		return router.addRoute(method,path,handle);
	}
	
	/**
        Add a Router rule. if config is done, will always erro. this will add to the default router.
        Params:
            method =  the HTTP method. 
            path   =  the request path.
            handle =  the delegate that handle the request.
            before =  The PipelineFactory that create the middleware list for the router rules, before  the router rule's handled execute.
            after  =  The PipelineFactory that create the middleware list for the router rules, after  the router rule's handled execute.
        Returns: the rule's element class. if can not add the rule will return null.
    */
	RouteElement addRoute(T)(string method, string path, T handle) if(is(T == HandleDelegate) || is(T == HandleFunction))
	{
		return _router.addRoute(method,path,handle);
	}

	/**
        Match the rule.if config is not done, will always erro.
        Params:
            domain = the domain group.if domain is empty , it will match in default router.
            method = the method group.
            path   = the path to match.
        Returns: 
            the pipeline has the Global MiddleWare ,Rule MiddleWare, Rule handler .
            the list is : Before Global MiddleWare -> Before Rule MiddleWare -> Rule handler -> After Rule MiddleWare -> After Global MiddleWare
            if don't match will  return null.
    */
	MachData match(string domain,string method, string path)
	{
		Router route = _router;
		if(_routerList.length > 0 && domain.length > 0)
		{
			route = _routerList.get(domain,null);
			if(route is null) route = _router;
		}

		return route.match(method,path);
	}
	
	/**
        Match the rule.if config is not done, will always erro. it will match in default router.
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
		return _router.match(method,path);
	}
	
	/**
        get config is done.
        if config is done, the add rule will erro.
        else math rule will erro.
    */
	@property bool condigDone(){return _router.condigDone;}
	
	/// set config done.
	void done()
	{
		_router.done();
		foreach(ref key, ref value; _routerList)
		{
			value.done();
		}
	}
	
	/// get the default router.
	Router defaultRouter(){return _router;}
	
	/// get the router in group. if domain is empty return the default router. if the domain is not exets, return null.
	Router getRouter(string domain)
	{
		if(domain.length == 0)
			return _router;
		return _routerList.get(domain,null);
	}

	
private:
	Router _router;
	Router[string] _routerList;
}

@property defaultRouter(){
	return _defaultRouter;
}

shared static this(){
	_defaultRouter = new RouterGroup();
}

private:
__gshared RouterGroup _defaultRouter;
