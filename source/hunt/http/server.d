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
module hunt.http.server;

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

import hunt.http.response;
import hunt.http.request;

alias HTTPPipeline = Pipeline!(ubyte[], HTTPResponse);

alias HTTPCALL = void delegate(Request req, Response res);

alias WEBSocketFactory = WebSocket delegate(const HTTPHeader header);
/**
    
*/

final class HTTPServer
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
        _server = new ServerBootstrap!HTTPPipeline(loop);
        _server.childPipeline(new shared HTTPPipelineFactory(this));
        _config = new HTTPConfig();
        _server.setReusePort(true);
        _server.heartbeatTimeOut(30);
    }

    auto keepAliveTimeOut(uint second)
    {
        _server.heartbeatTimeOut(second);
        return this;
    }

    /**
        set the ssl config.
        if you set and the config is not null, the Application will used https.
    */
    auto setSSLConfig(ServerSSLConfig config) 
    {
    	version (Windows)
    	{}
    	else
    	{
        	_server.setSSLConfig(config);
        	return this;
        }
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
    
    auto setCallBack(HTTPCALL cback)
    {
        _newReq = cback;
        return this;
    }
    
    auto setWebsocketFactory( WEBSocketFactory cback)
    {
	_websocket = cback;
	return this;
    }
    
    /// set the HTTPConfig maxBodySize.
    auto maxBodySize(uint size)
    {
        _config.maxBodySize = size;
        return this;
    }
    /// set the HTTPConfig maxHeaderSize.
    auto maxHeaderSize(uint size)
    {
        _config.maxHeaderSize = size;
        return this;
    }
    /// set the HTTPConfig headerStectionSize.
    auto headerStectionSize(uint size)
    {
        _config.headerStectionSize = size;
        return this;
    }
    /// set the HTTPConfig requestBodyStectionSize.
    auto requestBodyStectionSize(uint size)
    {
        _config.requestBodyStectionSize = size;
        return this;
    }
    /// set the HTTPConfig responseBodyStectionSize.
    auto responseBodyStectionSize(uint size)
    {
        _config.responseBodyStectionSize = size;
        return this;
    }
    
    /// get the http config.
    @property httpConfig(){return _config;}
    
    /**
        Start the HTTPServer server , and block current thread.
    */
    void run()
    {
	if(_newReq is null)
	    throw new Exception("the http callbacl is null!");
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
    HTTPCALL _newReq;
    ServerBootstrap!HTTPPipeline _server;
    HTTPConfig _config;
    WEBSocketFactory _websocket;
}

private:

class HttpServer : HTTPHandler
{
    this(HTTPServer server)
    {
        _server = server;
    }

    override void requestHandle(HTTPRequest req, HTTPResponse rep)
    {
        auto request = new Request(req);
        auto response = new Response(rep);
        _server._newReq(request, response);
    }

    override WebSocket newWebSocket(const HTTPHeader header)
    {
	if(_server._websocket)
	{
	    return _server._websocket(header);
	}
        return null;
    }
    
    override @property HTTPConfig config()
    {
        return _server.httpConfig();
    }

private:
    HTTPServer _server;
}

class HTTPPipelineFactory : PipelineFactory!HTTPPipeline
{
    import collie.socket.tcpsocket;
    this(HTTPServer app)
    {
        _app = cast(shared HTTPServer)app;
    }

    override HTTPPipeline newPipeline(TCPSocket sock)
    {
        auto pipeline = HTTPPipeline.create();
        pipeline.addBack(new TCPSocketHandler(sock));
        pipeline.addBack(new HttpServer(cast(HTTPServer)_app));
        pipeline.finalize();
        return pipeline;
    }
private:
    HTTPServer _app;
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
