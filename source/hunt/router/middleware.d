module hunt.router.middleware;

class Request{};
class Response{};

interface IMiddleWare
{
    void handle(Context ctx, Request req, Response res);
}

final class Context()
{
    this(Pipeline pipe, IMiddleWare middleWare){_pipe = pipe; _middleWare = middleWare;}
    private:
    IMiddleWare _middleWare;
    Pipeline _pipe;
    public:
    Context _next = null;
    void next(Request req, Response res)
    {
	if(_next)
	    _next.handle(req,res);
	else
	    _pipe.onOver(req,res);
    }
    private:
    void handle(Request req,  Response res)
    {
	_middleWare.handle(this,req,res);
    }
}
final class Pipeline
{
    this()
    {
	_first = new Context(this, null);
	_last = _first;
    }
    void  addHander(IMiddleWare hander)
    {
	Context cxt = new Context(this, hander);
	if(_first._next is null)
	{
	    _first._next = cxt;
	    _last = cxt;
	}
	else
	{
	    _last._next = cxt;
	    _last = cxt;
	}
    }
    void onOver(Request req, Response res)
    {
	
    }
    Context _first, _last;
    int len=0;
    bool isEmpty()
    {
	if(len)
	    return false;
	return true;
    }
}
