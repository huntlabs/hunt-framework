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

module hunt.console.application;

public import std.socket;
public import std.experimental.logger;
import std.conv;

import collie.bootstrap.server;
import collie.bootstrap.serversslconfig;
public import collie.socket.eventloop;
public import collie.socket.eventloopgroup;
public import collie.channel;

public import hunt.console.context;
public import hunt.console.fieldframe;
public import hunt.console.messagecoder;
public import hunt.console.middleware;
import hunt.web.router;

alias ConsolePipeLine = Pipeline!(ubyte[],Message);
alias ConsoleRouter = Router!(Message, ConsoleContext);
alias ConsoleHandler = void delegate(Message, ConsoleContext);


final class ConsoleApplication(bool litteEndian = false)
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
       _router = new ConsoleRouter();
        _404 = &default404;
        _server = new ServerBootstrap!ConsolePipeLine(loop);
        _server.childPipeline(new shared ConsolePipeLineFactory!litteEndian(this));
        _server.setReusePort(true);
        _crypt =  new NoCrypt();
    }

    /**
        Config the Apolication's Router .
        Params:
            config = the Config Class.
    */
    ConsoleApplication setRouterConfig(RouterConfigBase config)
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
    ConsoleApplication addRouter(ushort type, ConsoleHandler handle,
        shared RouterPipelineFactory before = null, shared RouterPipelineFactory after = null)
    {
        method = toUpper(method);
        router.addRouter("RPC",to!string(type),handle,before,after);
        return this;
    }
    
    /**
        Set The PipelineFactory that create the middleware list for all router rules, before  the router rule's handled execute.
    */
    ConsoleApplication setGlobalBeforePipelineFactory(shared RouterPipelineFactory before)
    {
        router.setGlobalBeforePipelineFactory(before);
        return this;
    }

    /**
        Set The PipelineFactory that create the middleware list for all router rules, after  the router rule's handled execute.
    */
    ConsoleApplication setGlobalAfterPipelineFactory(shared RouterPipelineFactory after)
    {
        router.setGlobalAfterPipelineFactory(after);
        return this;
    }

    /**
        Set The delegate that handle 404,when the router don't math the rule.
    */
    ConsoleApplication setNoFoundHandler(ConsoleHandler nofound)
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
    ConsoleApplication setSSLConfig(ServerSSLConfig config) 
    {
        _server.setSSLConfig(config);
        return this;
    } 
    
    /**
        Set the EventLoopGroup to used the multi-thread.
    */
    ConsoleApplication group(EventLoopGroup group)
    {
        _server.group(group);
        return this;
    }
    
    /**
        Set the accept Pipeline.
        See_Also:
            collie.bootstrap.server.ServerBootstrap pipeline
    */
    ConsoleApplication pipeline(shared AcceptPipelineFactory factory)
    {
        _server.pipeline(factory);
        return this;
    }
    
    /**
        Set the bind address.
    */
    ConsoleApplication bind(Address addr)
    {
        _server.bind(addr);
        return this;
    }

    /**
        Set the bind port, the ip address will be all.
    */
    ConsoleApplication bind(ushort port)
    {
        _server.bind(port);
        return this;
    }

    /**
        Set the bind address.
    */
    ConsoleApplication bind(string ip, ushort port)
    {
        _server.bind(ip,port);
        return this;
    }
    
    ConsoleApplication setMaxPackSize(uint size)
    {
        _maxPackSize = size;
    }
    
    ConsoleApplication setCompressType(CompressType type)
    {
        _contype = type;
    }
    
    ConsoleApplication setCompressLevel(uint lev)
    {
        _comLevel = lev;
    }
   
    ConsoleApplication setCryptHandler(CryptHandler crypt)
    {
        _crypt = crypt;
    }
   
    @property maxPackSize() const {return _maxPackSize;}
    @property compressType() const {return _comType;}
    @property compressLevel() const {return _comLevel;}
    @property cryptHandler() const {return _crypt;}
    
    @property cryptCopy() const {return _crypt.copy();}
    /**
        Start the ConsoleApplication server , and block current thread.
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
    /// the default handle when the router rule don't match.
    void default404(Request req, Response res)
    {
        res.Header.statusCode = 404;
        res.setContext("No Found");
        res.done();
    }

private:
    ConsoleRouter _router;
    ConsoleHandler _404;
    ServerBootstrap!HTTPPipeline _server;
    HTTPConfig _config;
    
private:
    uint _maxPackSize = 16 * 1024;
    CompressType _comType = CompressType.NONE;
    uint _comLevel = 6;
    CryptHandler _crypt;
}

private:

final class ConsoleServer(bool litteEndian) : ContexHandler
{
    this(shared ConsoleApplication!litteEndian app)
    {
        _app = app;
    }

protected:
    override void messageHandle(Message msg,ConsoleContext ctx)
    {
        ConsoleApplication app = cast(ConsoleApplication)_app;
        RouterPipeline pipe = null;
        TypeMessage tmsg = cast(TypeMessage)msg;
        if(!tmsg)
        {
            app._404(msg, ctx);
            return;
        }
        pipe = app.router.match("RPC",to!string(tmsg.type));
        if (pipe is null)
        {
            app._404(msg, ctx);
        }
        else
        {
            
            scope(exit)
            {
                import core.memory;
                pipe.destroy;
                GC.free(cast(void *)pipe);
            }
            pipe.handleActive(tmsg, ctx);
        }
    }
private:
    shared ConsoleApplication!litteEndian _app;
}

class ConsolePipeLineFactory(bool litteEndian) : PipelineFactory!ConsolePipeLine
{
    import collie.socket.tcpsocket;
    this(ConsoleApplication app)
    {
        _app = cast(shared ConsoleApplication)app;
    }

    override HTTPPipeline newPipeline(TCPSocket sock)
    {
        auto pipeline = HTTPPipeline.create();
        pipeline.addBack(new TCPSocketHandler(sock));
        pipeline.addBack(new FieldFrame!litteEndian(_app.maxPackSize(),_app.compressType(),_app.compressLevel()));
        pipeline.addBack(new MessageCoder!litteEndian(_app.cryptCopy()));
        pipeline.addBack(new ConsoleServer!litteEndian(_app));
        pipeline.finalize();
        return pipeline;
    }
private:
    ConsoleApplication _app;
}
