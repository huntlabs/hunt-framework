module hunt.webapplication;

public import std.socket;
public import std.experimental.logger;

import collie.bootstrap.server;
import collie.bootstrap.serversslconfig;
public import collie.socket.eventloop;
public import collie.socket.eventloopgroup;
public import collie.channel;
public import collie.codec.http.config;
import collie.codec.http;

public import hunt.router;
public import hunt.http;

alias HTTPPipeline = Pipeline!(ubyte[], HTTPResponse);

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
        _config = new HTTPConfig();
        _server.setReusePort(true);
    }
    
    WebApplication setRouterConfig(RouterConfig config)
    {
        setRouterConfigHelper!("__CALLACTION__",IController,Request, Response)
                                (_router,config);
        return this;
    }
    
    WebApplication addRouter(string method, string path, DOHandler handle,
        shared RouterPipelineFactory before = null, shared RouterPipelineFactory after = null)
    {
        router.addRouter(method,path,handle,before,after);
        return this;
    }
    
    WebApplication setGlobalBeforePipelineFactory(shared RouterPipelineFactory before)
    {
        router.setGlobalBeforePipelineFactory(before);
        return this;
    }

    WebApplication setGlobalAfterPipelineFactory(shared RouterPipelineFactory after)
    {
        router.setGlobalAfterPipelineFactory(after);
        return this;
    }

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

    @property router()
    {
        return _router;
    }
    
    WebApplication setSSLConfig(ServerSSLConfig config) 
    {
        _server.setSSLConfig(config);
        return this;
    } 
    
    WebApplication group(EventLoopGroup group)
    {
        _server.group(group);
        return this;
    }
    
    WebApplication pipeline(shared AcceptPipelineFactory factory)
    {
        _server.pipeline(factory);
        return this;
    }
    
    WebApplication bind(Address addr)
    {
        _server.bind(addr);
        return this;
    }

    WebApplication bind(ushort port)
    {
        _server.bind(port);
        return this;
    }

    WebApplication bind(string ip, ushort port)
    {
        _server.bind(ip,port);
        return this;
    }
    
    @property httpConfig(HTTPConfig config)
    {
        _config = config;
    }
    
    @property httpConfig(){return _config;}
    
    WebApplication maxBodySize(uint size)
    {
        _config.maxBodySize = size;
        return this;
    }
    
    WebApplication maxHeaderSize(uint size)
    {
        _config.maxHeaderSize = size;
        return this;
    }
    
    WebApplication headerStectionSize(uint size)
    {
        _config.headerStectionSize = size;
        return this;
    }
    
    WebApplication requestBodyStectionSize(uint size)
    {
        _config.requestBodyStectionSize = size;
        return this;
    }
    
    WebApplication responseBodyStectionSize(uint size)
    {
        _config.responseBodyStectionSize = size;
        return this;
    }
    
    void run()
    {
        router.done();
        _server.waitForStop();
    }
    
    void stop()
    {
        _server.stop();
    }

private:
    static void doHandle(WebApplication app,Request req, Response res)
    {
        trace("macth router : method: ", req.Header.methodString, "   path : ",req.Header.path);
        RouterPipeline pipe = app.router.match(req.Header.methodString, req.Header.path);
        if (pipe is null)
        {
            app._404(req, res);
        }
        else
        {
            scope(exit) pipe.destroy;
            if(pipe.matchData().length > 0)
            {
                pipe.swapMatchData(req.materef());
            }
            pipe.handleActive(req, res);
        }
    }

    void default404(Request req, Response res)
    {
        res.Header.statusCode = 404;
        res.setContext("No Found");
        res.done();
    }

private:
    HTTPRouter _router;
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

