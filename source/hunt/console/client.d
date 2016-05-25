module hunt.console.client;

public import std.socket;
public import std.experimental.logger;
import std.conv;

import collie.bootstrap.client;
public import collie.socket.eventloop;
public import collie.channel;

public import hunt.console.fieldframe;
public import hunt.console.messagecoder;

class ClientApplicatin(bool litteEndian = false) :  HandlerAdapter!(Message)
{
    this(EventLoop loop)
    {
       _router = new ConsoleRouter();
        _404 = &default404;
        _server = new ClientBootstrap!ConsolePipeLine(loop);
        _crypt =  new NoCrypt();
    }
    
    final auto heartbeatTimeOut(uint second)
    {
        _client.heartbeatTimeOut(second);
        return this;
    }
    
    final void connect(string ip, ushort port)
    {
        _client.setPipelineFactory(pipelineFactroy);
        _client.connect(ip,port);
    }
    
    final void connect(Address to)
    {
        _client.setPipelineFactory(pipelineFactroy);
        _client.connect(to);
    }
    
    final auto setMaxPackSize(uint size)
    {
        pipelineFactroy.setMaxPackSize(size);
        return this;
    }
    
    final auto setCompressType(CompressType type)
    {
        pipelineFactroy.setCompressType(type);
        return this;
    }
    
    final auto setCompressLevel(uint lev)
    {
        pipelineFactroy.setCompressLevel(lev);
        return this;
    }
   
    final auto setCryptHandler(CryptHandler crypt)
    in{
        assert(crypt);
    }body{
        pipelineFactroy.setCryptHandler(crypt);
        return this;
    }
   
   
    final @property maxPackSize() const {return pipelineFactroy.maxPackSize;}
    final @property compressType() const {return pipelineFactroy.comType;}
    final @property compressLevel() const {return pipelineFactroy.comLevel;}
    final @property cryptHandler() const {return pipelineFactroy.crypt;}
    
    final void run()
    {
        _client.waitForStop();
    }
    
    pragma(inline)
    final void write(ushort type,ubyte[] data)
    {
        context().fireWrite(new TypeMessage(type,data),&deleteMsg);
    }
    
    pragma(inline)
    final void write(Message msg)
    {
        context().fireWrite(msg,null);
    }
    
    pragma(inline)
    final void write(Message msg, void delegate(Message,uint) cback)
    {
        context().fireWrite(msg,cback);
    }
    
    pragma(inline)
    final void close()
    {
        context().fireClose();
    }
    
protected:
    void onRead(Message msg);
    void timeOut();
    void active();
    void unactive();
private:
    final override void transportActive(Context ctx){active();}
    final override void transportInActive(Context ctx){unactive();}
    final override void timeOut(Context ctx){timeOut();}
    final override void read(Context ctx, Rin msg){onRead(msg);}
private:
   final @property pipelineFactroy(){
        if(!_pipelineFactroy) {
            _pipelineFactroy = new ClientPipeLineFactory!litteEndian(this);
        }
        return _pipelineFactroy;
   }

   ClientBootstrap!ConsolePipeLine _client; 
   ClientPipeLineFactory!litteEndian _pipelineFactroy;   
}

private:
class ClientPipeLineFactory(bool litteEndian) : PipelineFactory!ConsolePipeLine
{
    import collie.socket.tcpsocket;
    this(HandlerAdapter!Message handler)
    {
        _app = cast(shared ConsoleApplication)app;
    }
    
    auto setMaxPackSize(uint size)
    {
        _maxPackSize = size;
    }
    
    auto setCompressType(CompressType type)
    {
        _contype = type;
    }
    
    auto setCompressLevel(uint lev)
    {
        _comLevel = lev;
    }
   
    auto setCryptHandler(CryptHandler crypt)
    in{
        assert(crypt);
    }body{
        _crypt = crypt;
    }
   
   
    @property maxPackSize() const {return _maxPackSize;}
    @property compressType() const {return _comType;}
    @property compressLevel() const {return _comLevel;}
    @property cryptHandler() const {return _crypt;}
    @property cryptCopy() const {return _crypt.copy();}

    override HTTPPipeline newPipeline(TCPSocket sock)
    {
        auto pipeline = HTTPPipeline.create();
        pipeline.addBack(new TCPSocketHandler(sock));
        pipeline.addBack(new FieldFrame!litteEndian(maxPackSize(),compressType(),compressLevel()));
        pipeline.addBack(new MessageCoder!litteEndian(cryptCopy()));
        pipeline.addBack(_handler);
        pipeline.finalize();
        return pipeline;
    }
private:
    HandlerAdapter!Message _handler;
    
    uint _maxPackSize = 16 * 1024;
    CompressType _comType = CompressType.NONE;
    uint _comLevel = 6;
    CryptHandler _crypt;
}