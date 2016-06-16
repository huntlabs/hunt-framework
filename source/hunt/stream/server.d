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

module hunt.stream.server;

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
    alias StreamCallBack = void delegate(Contex,Message);
    
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
        _server = new ServerBootstrap!ConsolePipeLine(loop);
        _server.childPipeline(new shared ConsolePipeLineFactory!(StreamServer!litteEndian)(this));
        _server.setReusePort(true);
        _crypt =  new NoCrypt();
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
    
    auto setCallBack(StreamCallBack cback)
    {
	_callBack = cback;
	return this;
    }
    
    @property streamCallBack(){return _callBack;}
   
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
        assert(_callBack);
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
    StreamCallBack _callBack;
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