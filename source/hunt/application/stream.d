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
import hunt.web.router;

final class StreamServer(bool litteEndian)
{
    alias Contex = ConsoleContext!(StreamServer!litteEndian);
    alias ConsoleRouter = Router!(Contex,Message);
    alias ConsoleHandler = void delegate(Contex,Message);
    alias MiddleWare = IMiddleWare!(Contex,Message);
    alias RouterPipeline = PipelineImpl!(Contex,Message);
    alias RouterPipelineFactory = IPipelineFactory!(Contex,Message);
    
    enum LittleEndian = litteEndian;
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
        _router = new ConsoleRouter();
        _404 = &default404;
        _server = new ServerBootstrap!ConsolePipeLine(loop);
        _server.childPipeline(new shared ConsolePipeLineFactory!(StreamServer!litteEndian)(this));
        _server.setReusePort(true);
        _crypt =  new NoCrypt();
        _timeOut = &timeOut;
    }

    /**
        Config the Apolication's Router .
        Params:
            config = the Config Class.
    */
 /*   auto setRouterConfig(RouterConfigBase config)
    {
        import hunt.web.http.controller;
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
    auto addRouter(string type, ConsoleHandler handle,
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
    auto setNoFoundHandler(ConsoleHandler nofound)
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
    
    auto timeOutHandler(void delegate(Contex) handler)
    {
        _timeOut = handler;
        return this;
    }
    
    auto setMaxPackSize(uint size)
    {
        _maxPackSize = size;
        return this;
    }
    
    auto setCompressType(CompressType type)
    {
        _comType = type;
        return this;
    }
    
    auto setCompressLevel(uint lev)
    {
        _comLevel = lev;
        return this;
    }
   
    auto setMessageDcoder(shared MessageDecode dcode)
    in{
        assert(dcode);
    }body{
        _dcoder = dcode;
        return this;
    }
   
    auto setCryptHandler(CryptHandler crypt)
    in{
        assert(crypt);
    }body{
        _crypt = crypt;
        return this;
    }
   
    @property maxPackSize() const shared {return _maxPackSize;}
    @property compressType() const shared {return _comType;}
    @property compressLevel() const shared {return _comLevel;}
    @property cryptHandler() const shared {return _crypt;}
    @property decoder() shared{return _dcoder;}
    
    @property CryptHandler cryptCopy() const shared {return cast(CryptHandler)(_crypt.copy());}
    
    
    /**
        Start the ConsoleServer server , and block current thread.
    */
    void run()
    {
        assert(_dcoder);
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

    pragma(inline)
    void do404(Contex contx, Message msg)
    {
	_404(contx,msg);
    }
    
    pragma(inline)
    void doTimeOut(Contex contx)
    {
	_timeOut(contx);
    }
protected :
    /// the default handle when the router rule don't match.
    final void default404(Contex contx, Message msg)
    {
        contx.close();
    }
    
    final void timeOut(Contex contx)
    {
        trace("connect time out");
        contx.close();
    }

    ConsoleHandler _404;
    void delegate(Contex) _timeOut;
private:
    ConsoleRouter _router;
    ServerBootstrap!ConsolePipeLine _server;
private:
    uint _maxPackSize = 16 * 1024;
    CompressType _comType = CompressType.NONE;
    uint _comLevel = 6;
    CryptHandler _crypt;
    
    shared MessageDecode _dcoder;
}

private:

class ConsolePipeLineFactory(ConsoleServer) : PipelineFactory!ConsolePipeLine
{
    enum LittleEndian = ConsoleServer.LittleEndian;
    import collie.socket.tcpsocket;
    this(ConsoleServer app)
    {
        _app = cast(shared ConsoleServer)app;
    }

    override ConsolePipeLine newPipeline(TCPSocket sock)
    {
        auto pipeline = ConsolePipeLine.create();
        pipeline.addBack(new TCPSocketHandler(sock));
        pipeline.addBack(new FieldFrame!LittleEndian(_app.maxPackSize(),_app.compressType(),_app.compressLevel()));
        pipeline.addBack(new MessageCoder(_app.decoder(),_app.cryptCopy()));
        pipeline.addBack(new ContexHandler!ConsoleServer(_app));
        pipeline.finalize();
        return pipeline;
    }
private:
    ConsoleServer _app;
}