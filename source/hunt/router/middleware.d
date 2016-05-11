module hunt.router.middleware;

class REQ{};
class RES{};

interface IMiddleWare(REQ, RES)
{
    void handle(Context ctx, REQ req, RES res);
}

final class Context(REQ, RES)
{
    this(Pipeline pipe, IMiddleWare middleWare){_pipe = pipe; _middleWare = middleWare;}
    private:
    IMiddleWare _middleWare;
    Pipeline _pipe;
    public:
    Context _next = null;
    void next(REQ req, RES res)
    {
	if(_next)
	    _next.handle(req,res);
	else
	    _pipe.onOver(req,res);
    }
    private:
    void handle(REQ req,  RES res)
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
    void onOver(REQ req, RES res)
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
