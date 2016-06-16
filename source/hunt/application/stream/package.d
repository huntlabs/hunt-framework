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

module hunt.application.stream;

public import std.socket;
public import std.experimental.logger;
import std.conv;

import collie.bootstrap.server;
import collie.bootstrap.serversslconfig;
public import collie.socket.eventloop;
public import collie.socket.eventloopgroup;
public import collie.channel;

public import hunt.stream.context;
public import hunt.stream.fieldframe;
public import hunt.stream.messagecoder;
public import hunt.stream.server;
import hunt.web.router;

final class StreamApplication(bool litteEndian)
{
    alias Server = StreamServer!litteEndian;
    alias Contex = Server.Contex;
    
    alias ConsoleRouter = Router!(Contex,Message);
    alias ConsoleHandler = void delegate(Contex,Message);
    alias MiddleWare = IMiddleWare!(Contex,Message);
    alias RouterPipeline = PipelineImpl!(Contex,Message);
    alias RouterPipelineFactory = IPipelineFactory!(Contex,Message);
    
    
    enum LittleEndian = litteEndian;
    /// default Constructor
    this()
    {
        _router = new ConsoleRouter();
        _server = new Server(new EventLoop());
        _server.setCallBack(&handleMessage);
    }

    /**
        Config the Apolication's Router .
        Params:
            config = the Config Class.
    */
 /*   auto setRouterConfig(RouterConfigBase config)
    {
        import hunt.http.controller;
        setRouterConfigHelper!("__CALLACTION__",IController,ConsoleRouter)
                                (_router,config);
        return this;
    }
   */
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
    auto addRouter(string type, Server.StreamCallBack handle,
        shared RouterPipelineFactory before = null, shared RouterPipelineFactory after = null)
    {
        router.addRouter("RPC",type,handle,before,after);
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
    auto setNoFoundHandler(Server.StreamCallBack nofound)
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
    auto setSSLConfig(ServerSSLConfig config) 
    {
        _server.setSSLConfig(config);
        return this;
    } 
    
    /**
        Set the EventLoopGroup to used the multi-thread.
    */
    auto group(EventLoopGroup group)
    {
        _server.group(group);
        return this;
    }
    
    /**
        Set the accept Pipeline.
        See_Also:
            collie.bootstrap.server.ServerBootstrap pipeline
    */
    auto pipeline(shared AcceptPipelineFactory factory)
    {
        _server.pipeline(factory);
        return this;
    }
    
    /**
        Set the bind address.
    */
    auto bind(Address addr)
    {
        _server.bind(addr);
        return this;
    }

    /**
        Set the bind port, the ip address will be all.
    */
    auto bind(ushort port)
    {
        _server.bind(port);
        return this;
    }

    /**
        Set the bind address.
    */
    auto bind(string ip, ushort port)
    {
        _server.bind(ip,port);
        return this;
    }
    
    auto heartbeatTimeOut(uint second)
    {
        _server.heartbeatTimeOut(second);
        return this;
    }
    
    auto setMaxPackSize(uint size)
    {
        _server.setMaxPackSize(size);
        return this;
    }
    
    auto setCompressType(CompressType type)
    {
        _server.setCompressType(type);
        return this;
    }
    
    auto setCompressLevel(uint lev)
    {
        _server.setCompressLevel(lev);
        return this;
    }
   
    auto setMessageDcoder(shared MessageDecode dcode)
    {
        _server.setMessageDcoder(dcode);
        return this;
    }

    auto setCryptHandler(CryptHandler crypt)
    {
        _server.setCryptHandler(crypt);
        return this;
    }
    
    
    /**
        Start the ConsoleServer server , and block current thread.
    */
    void run()
    {
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

protected :
    void handleMessage(Contex ctx ,Message msg)
    {
        //do router
        if(msg is null)
        {
            _404(ctx,msg);
            return;
        }
        
        auto pipe = _router.match("RPC",msg.type());
        if (pipe is null)
        {
            _404(ctx,msg);
        }
        else
        {
            
            scope(exit)
            {
                import core.memory;
                pipe.destroy;
                GC.free(cast(void *)pipe);
            }
            pipe.handleActive( ctx,msg);
        }
    }
    
    void def404(Contex ctx ,Message msg)
    {
        error("router no found!");
        ctx.close();
    }
    
    Server.StreamCallBack _404;
private:
    ConsoleRouter _router;
    Server _server;
}