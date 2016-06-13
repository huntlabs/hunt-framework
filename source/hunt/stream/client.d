module hunt.stream.client;

public import std.socket;
public import std.experimental.logger;
import std.conv;

import collie.bootstrap.client;
public import collie.socket.eventloop;
public import collie.channel;

import hunt.stream.context : ConsolePipeLine;
public import hunt.stream.fieldframe;
public import hunt.stream.messagecoder;

abstract class StreamClient(bool litteEndian = false) :  HandlerAdapter!(Message)
{
    this(EventLoop loop)
    {
        _client = new ClientBootstrap!ConsolePipeLine(loop);   
    }
    
    final auto heartbeatTimeOut(uint second)
    {
        _client.heartbeatTimeOut(second);
        return this;
    }
    
    final void connect(string ip, ushort port)
    {
        assert(decoder);
        _client.setPipelineFactory(pipelineFactroy);
        _client.connect(ip,port);
    }
    
    final void connect(Address to)
    {
        assert(decoder);
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
   
    auto setMessageDcoder(shared MessageDecode dcode)
    in{
        assert(dcode);
    }body{
        pipelineFactroy.setMessageDcoder(dcode);
        return this;
    }
   
    final @property maxPackSize()  {return pipelineFactroy.maxPackSize;}
    final @property compressType()  {return pipelineFactroy.compressType;}
    final @property compressLevel()  {return pipelineFactroy.compressLevel;}
    final @property cryptHandler()  {return pipelineFactroy.cryptHandler;}
    @property decoder() {return pipelineFactroy.decoder;}
    
    pragma(inline)
    final void doWrite(Message msg, void delegate(Message,uint) cback = null)
    {
        context().fireWrite(msg,cback);
    }
    
    pragma(inline)
    final void doClose()
    {
        context().fireClose();
    }
    
    @property EventLoop eventLoop(){return _client.eventLoop();}
protected:
    void onRead(Message msg);
    void onTimeOut();
    void onActive();
    void onUnactive();
    
    final void deleteMsg(Message msg, uint len)
    {
        import collie.utils.memory;
        gcFree(msg);
        if(len == 0)
        {
            context().fireClose();
        }
    }
public:
    final override void transportActive(Context ctx){
        trace("transportActive");
        onActive();
    }
    final override void transportInactive(Context ctx){
        trace("transportInactive");
        onUnactive();
    }
    final override void timeOut(Context ctx){
        trace("timeOut");
        onTimeOut();
    }
    final override void read(Context ctx, Message msg){trace("read");onRead(msg);}
private:
   final @property pipelineFactroy(){
        if(!_pipelineFactroy) {
            _pipelineFactroy = new shared ClientPipeLineFactory!litteEndian(this);
        }
        return _pipelineFactroy;
   }

   ClientBootstrap!ConsolePipeLine _client; 
   shared ClientPipeLineFactory!litteEndian _pipelineFactroy;   
}

private:
class ClientPipeLineFactory(bool litteEndian) : PipelineFactory!ConsolePipeLine
{
    import collie.socket.tcpsocket;
    this(HandlerAdapter!Message handler)
    {
        _handler = cast(shared HandlerAdapter!Message)handler;
        _crypt =  new NoCrypt();
    }
    
    auto setMaxPackSize(uint size)
    {
        _maxPackSize = size;
    }
    
    auto setCompressType(CompressType type)
    {
        _comType = type;
    }
    
    auto setCompressLevel(uint lev)
    {
        _comLevel = lev;
    }
   
    auto setCryptHandler(CryptHandler crypt)
    in{
        assert(crypt);
    }body{
        _crypt = cast(shared CryptHandler)crypt;
    }
    
    auto setMessageDcoder(shared MessageDecode dcode)
    {
        _dcoder = dcode;
    }
   
   
    @property maxPackSize() const {return _maxPackSize;}
    @property compressType() const {return _comType;}
    @property compressLevel() const {return _comLevel;}
    @property cryptHandler() const {return _crypt;}
    @property cryptCopy() const {return _crypt.copy();}
    @property decoder() shared{return _dcoder;}

    override ConsolePipeLine newPipeline(TCPSocket sock)
    {
        trace("New client : newPipeline");
        auto pipeline = ConsolePipeLine.create();
        pipeline.addBack(new TCPSocketHandler(sock));
        pipeline.addBack(new FieldFrame!litteEndian(maxPackSize(),compressType(),compressLevel()));
        pipeline.addBack(new MessageCoder(_dcoder,cryptCopy()));
        pipeline.addBack(cast(HandlerAdapter!Message)_handler);
        pipeline.finalize();
        return pipeline;
    }
private:
    HandlerAdapter!Message _handler;
    
    uint _maxPackSize = 16 * 1024;
    CompressType _comType = CompressType.NONE;
    uint _comLevel = 6;
    CryptHandler _crypt;
    
    shared MessageDecode _dcoder;
}