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
module hunt.web.application;

public import std.socket;
public import std.experimental.logger;
import std.uni;

import collie.bootstrap.server;
import collie.bootstrap.serversslconfig;
public import collie.socket.eventloop;
public import collie.socket.eventloopgroup;
public import collie.channel;
public import collie.codec.http.config;
import collie.codec.http;

public import hunt.web.router;
public import hunt.web.http;

alias HTTPPipeline = Pipeline!(ubyte[], HTTPResponse);

/**
    
*/

final class WebApplication
{
    /// default Constructor
    this()
    {
        this(new EventLoop());
    }
    
    /**
        Constructor, Set the default EventLoop.
        Params:
            loop = the default EventLoop
    */
    this(EventLoop loop)
    {
       _router = new HTTPRouterGroup();
        _404 = &default404;
        _server = new ServerBootstrap!HTTPPipeline(loop);
        _server.childPipeline(new shared HTTPPipelineFactory(this));
        _config = new HTTPConfig();
        _server.setReusePort(true);
    }
    
    /**
        Config the Apolication's Router .
        Params:
            config = the Config Class.
    */
    WebApplication setRouterConfig(RouterConfig config)
    {
        setRouterConfigHelper!("__CALLACTION__",IController,HTTPRouterGroup)
                                (_router,config);
        return this;
    }
   
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
    WebApplication addRouter(string domain, string method, string path, DOHandler handle,
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
    WebApplication addRouter(string method, string path, DOHandler handle,
        shared RouterPipelineFactory before = null, shared RouterPipelineFactory after = null)
    {
        method = toUpper(method);
        router.addRouter(method,path,handle,before,after);
        return this;
    }
    
    /**
        Set The PipelineFactory that create the middleware list for all router rules, before  the router rule's handled execute.
    */
    WebApplication setGlobalBeforePipelineFactory(shared RouterPipelineFactory before)
    {
        router.setGlobalBeforePipelineFactory(before);
        return this;
    }

    /**
        Set The PipelineFactory that create the middleware list for all router rules, after  the router rule's handled execute.
    */
    WebApplication setGlobalAfterPipelineFactory(shared RouterPipelineFactory after)
    {
        router.setGlobalAfterPipelineFactory(after);
        return this;
    }

    /**
        Set The delegate that handle 404,when the router don't math the rule.
    */
    WebApplication setNoFoundHandler(DOHandler nofound)
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
    
    /**
        set the ssl config.
        if you set and the config is not null, the Application will used https.
    */
    WebApplication setSSLConfig(ServerSSLConfig config) 
    {
        _server.setSSLConfig(config);
        return this;
    } 
    
    /**
        Set the EventLoopGroup to used the multi-thread.
    */
    WebApplication group(EventLoopGroup group)
    {
        _server.group(group);
        return this;
    }
    
    /**
        Set the accept Pipeline.
        See_Also:
            collie.bootstrap.server.ServerBootstrap pipeline
    */
    WebApplication pipeline(shared AcceptPipelineFactory factory)
    {
        _server.pipeline(factory);
        return this;
    }
    
    /**
        Set the bind address.
    */
    WebApplication bind(Address addr)
    {
        _server.bind(addr);
        return this;
    }

    /**
        Set the bind port, the ip address will be all.
    */
    WebApplication bind(ushort port)
    {
        _server.bind(port);
        return this;
    }

    /**
        Set the bind address.
    */
    WebApplication bind(string ip, ushort port)
    {
        _server.bind(ip,port);
        return this;
    }
    
    /**
        Set the Http config.
        See_Also:
            collie.codec.http.config.HTTPConfig
    */
    
    @property httpConfig(HTTPConfig config)
    {
        _config = config;
    }
    /// get the http config.
    @property httpConfig(){return _config;}
    
    /// set the HTTPConfig maxBodySize.
    WebApplication maxBodySize(uint size)
    {
        _config.maxBodySize = size;
        return this;
    }
    /// set the HTTPConfig maxHeaderSize.
    WebApplication maxHeaderSize(uint size)
    {
        _config.maxHeaderSize = size;
        return this;
    }
    /// set the HTTPConfig headerStectionSize.
    WebApplication headerStectionSize(uint size)
    {
        _config.headerStectionSize = size;
        return this;
    }
    /// set the HTTPConfig requestBodyStectionSize.
    WebApplication requestBodyStectionSize(uint size)
    {
        _config.requestBodyStectionSize = size;
        return this;
    }
    /// set the HTTPConfig responseBodyStectionSize.
    WebApplication responseBodyStectionSize(uint size)
    {
        _config.responseBodyStectionSize = size;
        return this;
    }
    
    /**
        Start the WebApplication server , and block current thread.
    */
    void run()
    {
        router.done();
        _server.waitForStop();
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
    static void doHandle(WebApplication app,Request req, Response res)
    {
        trace("macth router : method: ", req.Header.methodString, "   path : ",req.Header.path, " host: ", req.Header.host);
        RouterPipeline pipe = null;
	pipe = app.router.match(req.Header.host,req.Header.methodString, req.Header.path);

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

private:
    HTTPRouterGroup _router;
    DOHandler _404;
    ServerBootstrap!HTTPPipeline _server;
    HTTPConfig _config;
}

private:

class HttpServer : HTTPHandler
{
    this(shared WebApplication app)
    {
        _app = app;
    }

    override void requestHandle(HTTPRequest req, HTTPResponse rep)
    {
        auto request = new Request(req);
        auto response = new Response(rep);
        _app.doHandle(cast(WebApplication)_app,request, response);
    }

    override WebSocket newWebSocket(const HTTPHeader header)
    {
        return null;
    }
    
    override @property HTTPConfig config()
    {
        return cast(HTTPConfig)(_app._config);
    }

private:
    shared WebApplication _app;
}

class HTTPPipelineFactory : PipelineFactory!HTTPPipeline
{
    import collie.socket.tcpsocket;
    this(WebApplication app)
    {
        _app = cast(shared WebApplication)app;
    }

    override HTTPPipeline newPipeline(TCPSocket sock)
    {
        auto pipeline = HTTPPipeline.create();
        pipeline.addBack(new TCPSocketHandler(sock));
        pipeline.addBack(new HttpServer(_app));
        pipeline.finalize();
        return pipeline;
    }
private:
    WebApplication _app;
}

/*class EchoWebSocket : WebSocket
{
    override void onClose()
    {
            writeln("websocket closed");
    }

    override void onTextFrame(Frame frame)
    {
            writeln("get a text frame, is finna : ", frame.isFinalFrame, "  data is :", cast(string)frame.data);
            sendText("456789");
    //      sendBinary(cast(ubyte[])"456123");
    //      ping(cast(ubyte[])"123");
    }

    override void onPongFrame(Frame frame)
    {
            writeln("get a text frame, is finna : ", frame.isFinalFrame, "  data is :", cast(string)frame.data);
    }

    override void onBinaryFrame(Frame frame)
    {
            writeln("get a text frame, is finna : ", frame.isFinalFrame, "  data is :", cast(string)frame.data);
    }
}
*/
