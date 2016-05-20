module hunt.web.router.routergroup;

import hunt.web.router.router;
import hunt.web.router.middleware;
import hunt.web.router.utils;


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
    
    void setGlobalBeforePipelineFactory(shared PipelineFactory before)
    {
        _gbefore = before;
    }

    void setGlobalAfterPipelineFactory(shared PipelineFactory after)
    {
        _gafter = after;
    }

    void addRouter(string domain,Route router)
    {
        _routerList[domain] = router;
    }
    
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
 
    
     RouterElement addRouter(string method, string path, HandleDelegate handle,
        shared PipelineFactory before = null, shared PipelineFactory after = null)
    {
        return _router.addRouter(method,path,handle,before,after);
    }
    
  
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
  
    Pipeline match(string method, string path)
    {
        return _router.match(method,path);
    }
    
    @property bool condigDone(){return _router.condigDone;}
    
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
    
    Route defaultRouter(){return _router;}
    
    Route getRouter(string domain)
    {
        if(domain.length == 0)
            return _router;
        return _routerList.get(domain,null);
    }
    
    Pipeline getGlobalBrforeMiddleware()
    {
        if (_gbefore)
            return _gbefore.newPipeline();
        else
            return null;
    }

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
