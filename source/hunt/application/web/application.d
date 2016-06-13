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
module hunt.application.web.application;

public import std.socket;
public import std.experimental.logger;
import std.uni;

//import collie.bootstrap.server;
import collie.bootstrap.serversslconfig;
public import collie.socket.eventloop;
public import collie.socket.eventloopgroup;
public import collie.channel;
public import collie.codec.http.config;
import collie.codec.http;

public import hunt.web;
import hunt.application.web.config;
/**
    
*/

final class WebApplication
{
    static setConfig(WebConfig config)
    {
        assert(config);
        if(_app is null)
        {
            _app = new WebApplication;
        }
        _app._config = config;
        _app.upConfig();
    }
    
    static @property app(){return _app;}

    /**
        Add a Router rule
        Params:
            domain =  the rule's domain group.
            method =  the HTTP method. 
            path   =  the request path.
            handle =  the delegate that handle the request.
            before =  The PipelineFactory that create the middleware list for the router rules, before  the router rule's handled execute.
            after  =  The PipelineFactory that create the middleware list for the router rules, after  the router rule's handled execute.
    */
    auto addRouter(string domain, string method, string path, DOHandler handle,
        shared RouterPipelineFactory before = null, shared RouterPipelineFactory after = null)
    {
        method = toUpper(method);
        router.addRouter(domain,method,path,handle,before,after);
        return this;
    }

    /**
        Add a Router rule
        Params:
            method =  the HTTP method. 
            path   =  the request path.
            handle =  the delegate that handle the request.
            before =  The PipelineFactory that create the middleware list for the router rules, before  the router rule's handled execute.
            after  =  The PipelineFactory that create the middleware list for the router rules, after  the router rule's handled execute.
    */
    auto addRouter(string method, string path, DOHandler handle,
        shared RouterPipelineFactory before = null, shared RouterPipelineFactory after = null)
    {
        method = toUpper(method);
        router.addRouter(method,path,handle,before,after);
        return this;
    }
    
    /**
        Set The PipelineFactory that create the middleware list for all router rules, before  the router rule's handled execute.
    */
    auto setGlobalBeforePipelineFactory(shared RouterPipelineFactory before)
    {
        router.setGlobalBeforePipelineFactory(before);
        return this;
    }

    /**
        Set The PipelineFactory that create the middleware list for all router rules, after  the router rule's handled execute.
    */
    auto setGlobalAfterPipelineFactory(shared RouterPipelineFactory after)
    {
        router.setGlobalAfterPipelineFactory(after);
        return this;
    }

    /**
        Set The delegate that handle 404,when the router don't math the rule.
    */
    auto setNoFoundHandler(DOHandler nofound)
    in
    {
        assert(nofound !is null);
    }
    body
    {
        _404 = nofound;
        return this;
    }

    /// get the router.
    @property router()
    {
        return _router;
    }
    
    @property server(){return _server;}
    
    @property mainLoop(){return _mainLoop;}
    
    @property loopGroup(){return _group;}
    
    @property appConfig(){return _config;}
    
    
    /**
        Start the HTTPServer server , and block current thread.
    */
    void run()
    {
        auto config = _config.routerConfig();
        if(config !is null)
            setRouterConfigHelper!("__CALLACTION__",IController,HTTPRouterGroup)
                            (_router,config);
        router.done();
        _server.run();
    }
    
    /**
        Stop the server.
    */
    void stop()
    {
        _server.stop();
    }

private:
    /// math the router and start handle the middleware and handle.
    void doHandle(Request req, Response res)
    {
        trace("macth router : method: ", req.Header.methodString, "   path : ",req.Header.path, " host: ", req.Header.host);
        RouterPipeline pipe = null;
	pipe = _router.match(req.Header.host,req.Header.methodString, req.Header.path);

        if (pipe is null)
        {
            app._404(req, res);
        }
        else
        {
            
            scope(exit)
            {
                import core.memory;
                pipe.destroy;
                GC.free(cast(void *)pipe);
            }
            if(pipe.matchData().length > 0)
            {
                pipe.swapMatchData(req.materef());
            }
            pipe.handleActive(req, res);
        }
    }

    /// the default handle when the router rule don't match.
    void default404(Request req, Response res)
    {
        res.Header.statusCode = 404;
        res.setContext("No Found");
        res.done();
    }
    
    void upConfig()
    {
        _server.bind(_config.bindAddress());
        _server.setSSLConfig(_config.sslConfig());
        auto ts = _config.threadSize() - 1;
        if(ts > 0)
        {
            _group = new EventLoopGroup(ts);
            _server.group(_group);
        } 
        _server.keepAliveTimeOut(_config.keepAliveTimeOut());
        _server.maxBodySize(_config.httpMaxBodySize());
        _server.maxHeaderSize(_config.httpMaxHeaderSize());
        _server.headerStectionSize(_config.httpHeaderStectionSize());
        _server.requestBodyStectionSize(_config.httpRequestBodyStectionSize());
        _server.responseBodyStectionSize(_config.httpResponseBodyStectionSize());
        _wfactory = _config.webSocketFactory();
        if(_wfactory is null)
        {
            _server.setWebsocketFactory(null);  
        }
        else
        {
            _server.setWebsocketFactory(&_wfactory.newWebSocket);
        }
    }
    
    /// default Constructor
    this()
    {
       _mainLoop = new EventLoop();
       _server = new HTTPServer(_mainLoop);
       _router = new HTTPRouterGroup();
       _server.setCallBack(&doHandle);
       _404 = &default404;
    }

    __gshared static WebApplication _app;
private:
    HTTPRouterGroup _router;
    DOHandler _404;
//    ServerBootstrap!HTTPPipeline _server;
    HTTPServer _server;
    EventLoop _mainLoop;
    EventLoopGroup _group;
    WebSocketFactory _wfactory;
    WebConfig _config;
}

