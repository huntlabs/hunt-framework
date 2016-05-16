module hunt.webapplication;

import hunt.router;
import hunt.http.request;
import hunt.http.response;

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
        _router = new HTTPRouter();
        _404 = &default404;
    }

    void setNoFoundHandler(DOHandler nofound)
    in
    {
        assert(nofound !is null);
    }
    body
    {
        _404 = nofound;
    }

    @property router()
    {
        return _router;
    }

private:
    void doHandle(Request req, Response res)
    {
        RouterPipeline pipe = _app.router.match(req.Header.methodString, req.Header.path);
        if (pipe is null)
        {
            _404(req, res);
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

}

private:

class HttpServer : HTTPHandler
{
    this(WebApplication app)
    {
        _app = app;
    }

    override void requestHandle(HTTPRequest req, HTTPResponse rep)
    {
        auto request = new Request(req);
        auto response = new Response(rep);
        _app.doHandle(request, response);
    }

    override WebSocket newWebSocket(const HTTPHeader header)
    {
        return null;
    }

private:
    WebApplication _app;
}

class HTTPPipelineFactory : PipelineFactory!HTTPPipeline
{
    this(WebApplication app)
    {
        _app = app;
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
