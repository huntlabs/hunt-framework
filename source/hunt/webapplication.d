module hunt.webapplication;

import std.socket;

import collie.bootstrap.server;
import collie.bootstrap.serversslconfig;
import collie.socket.eventloop;
import collie.socket.eventloopgroup;
import collie.channel;
import collie.codec.http;

import hunt.router;
import hunt.http.request;
import hunt.http.response;
import hunt.http.controller;

import hunt.router.router;
import hunt.router.middleware;

alias HTTPPipeline = Pipeline!(ubyte[], HTTPResponse);
alias HTTPRouter = Router!(Request, Response);
alias RouterPipeline = PipelineImpl!(Request, Response);
alias RouterPipelineFactory = IPipelineFactory!(Request, Response);
alias MiddleWare = IMiddleWare!(Request, Response);
alias DOHandler = void delegate(Request, Response);

final class WebApplication
{
    this()
    {
        this(new EventLoop());
    }
    
    this(EventLoop loop)
    {
       _router = new HTTPRouter();
        _404 = &default404;
        _server = new ServerBootstrap!HTTPPipeline(loop);
        _server.childPipeline(new shared HTTPPipelineFactory(this));
    }
    
    auto setRouterConfig(RouterConfig config)
    {
        setRouterConfigHelper!("__CALLACTION__",IController,Request, Response)
                                (_router,config);
    }
    
    auto addRouter(string method, string path, DOHandler handle,
        shared RouterPipelineFactory before = null, shared RouterPipelineFactory after = null)
    {
        router.addRouter(method,path,handle,before,after);
        return this;
    }
    
    auto setGlobalBeforePipelineFactory(shared RouterPipelineFactory before)
    {
        router.setGlobalBeforePipelineFactory(before);
        return this;
    }

    auto setGlobalAfterPipelineFactory(shared RouterPipelineFactory after)
    {
        router.setGlobalAfterPipelineFactory(after);
        return this;
    }

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

    @property router()
    {
        return _router;
    }
    
    auto setSSLConfig(ServerSSLConfig config) 
    {
        _server.setSSLConfig(config);
        return this;
    } 
    
    auto group(EventLoopGroup group)
    {
        _server.group(group);
        return this;
    }
    
    auto pipeline(shared AcceptPipelineFactory factory)
    {
        _server.pipeline(factory);
        return this;
    }
    
    auto bind(Address addr)
    {
        _server.bind(addr);
        return this;
    }

    auto bind(ushort port)
    {
        _server.bind(port);
        return this;
    }

    auto bind(string ip, ushort port)
    {
        _server.bind(ip,port);
        return this;
    }
    
    void run()
    {
        _server.waitForStop();
    }
    
    void stop()
    {
        _server.stop();
    }

private:
    static void doHandle(WebApplication app,Request req, Response res)
    {
        RouterPipeline pipe = app.router.match(req.Header.methodString, req.Header.path);
        if (pipe is null)
        {
            app._404(req, res);
        }
        else
        {
            pipe.handleActive(req, res);
        }
    }

    void default404(Request req, Response res)
    {
        res.Header.statusCode = 404;
        res.setContext("Mo Found");
        res.done();
    }

private:
    HTTPRouter _router;
    DOHandler _404;
    ServerBootstrap!HTTPPipeline _server;
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

