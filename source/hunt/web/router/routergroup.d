module hunt.web.router.routergroup;

import hunt.web.router.router;
import hunt.web.router.middleware;
import hunt.web.router.utils;

/**
    the router group.
*/
final class RouterGroup(REQ,RES)
{
    alias Route                 = Router!(REQ,RES);
    alias RouterElement         = Route.RouterElement;
    alias HandleDelegate        = Route.HandleDelegate;
    alias Pipeline              = Route.Pipeline;
    alias PipelineFactory       = Route.PipelineFactory;
    
    alias Request               = REQ;
    alias Response              = RES;
    
    this()
    {
       _router = new  Route();
    }
    
    /**
        Set The PipelineFactory that create the middleware list for this rules, before  the router rule's handled execute.
    */
    void setGlobalBeforePipelineFactory(shared PipelineFactory before)
    {
        _gbefore = before;
    }

    /**
        Set The PipelineFactory that create the middleware list for this rules, after  the router rule's handled execute.
    */
    void setGlobalAfterPipelineFactory(shared PipelineFactory after)
    {
        _gafter = after;
    }

    /**
        Add a Router in this Group;
        Params:
            domain = the domain. if the domain is exets, will override.
            router = the router will add.
    */
    void addRouter(string domain,Route router)
    {
        _routerList[domain] = router;
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
    RouterElement addRouter(string domain, string method,string path, HandleDelegate handle,
        shared PipelineFactory before = null, shared PipelineFactory after = null)
    {
        if(domain.length == 0)
        {
            return _router.addRouter(method,path,handle,before,after);
        } 
        
        
        auto router = _routerList.get(domain,null);
        if(router is null)
        {
            router = new Route();
            _routerList[domain] = router;
        }
        
        return router.addRouter(method,path,handle,before,after);
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
    RouterElement addRouter(string method, string path, HandleDelegate handle,
        shared PipelineFactory before = null, shared PipelineFactory after = null)
    {
        return _router.addRouter(method,path,handle,before,after);
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
    Pipeline match(string domain,string method, string path)
    {
        if(_routerList.length == 0 || domain.length == 0)
        {
            return _router.match(method,path);
        }

        auto router = _routerList.get(domain,null);
        if(router is null)
            return _router.match(method,path);
        else
            return router.match(method,path);
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
    Pipeline match(string method, string path)
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
        _router.setGlobalAfterPipelineFactory(_gafter);
        _router.setGlobalBeforePipelineFactory(_gbefore);
        _router.done();
        foreach(ref key, ref value; _routerList)
        {
            value.setGlobalAfterPipelineFactory(_gafter);
            value.setGlobalBeforePipelineFactory(_gbefore);
            value.done();
        }
    }
    
    /// get the default router.
    Route defaultRouter(){return _router;}
    
    /// get the router in group. if domain is empty return the default router. if the domain is not exets, return null.
    Route getRouter(string domain)
    {
        if(domain.length == 0)
            return _router;
        return _routerList.get(domain,null);
    }
    
    /**
        Get PipelineFactory that create the middleware list for all router rules.
    */
    Pipeline getGlobalBrforeMiddleware()
    {
        if (_gbefore)
            return _gbefore.newPipeline();
        else
            return null;
    }

    /**
        Get The PipelineFactory that create the middleware list for all router rules.
    */
    Pipeline getGlobalAfterMiddleware()
    {
        if (_gafter)
            return _gafter.newPipeline();
        else
            return null;
    }

private:
    Route _router;
    Route[string] _routerList;
    
    shared PipelineFactory _gbefore = null;
    shared PipelineFactory _gafter = null;
}
