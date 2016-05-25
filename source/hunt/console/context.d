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

module hunt.console.context;


import collie.channel.handler;
import collie.channel.handlercontext;
import collie.channel.pipeline;

import hunt.console.messagecoder;
import hunt.web.router;

final class ConsoleContext(ConsoleApplication)
{
    pragma(inline)
    void write(ushort type,ubyte[] data)
    {
        _header.context().fireWrite(new TypeMessage(type,data),&deleteMsg);
    }
    
    pragma(inline)
    void write(Message msg)
    {
        _header.context().fireWrite(msg,null);
    }
    
    pragma(inline)
    void write(Message msg, void delegate(Message,uint) cback)
    {
        _header.context().fireWrite(msg,cback);
    }
    
    pragma(inline)
    void close()
    {
        _header.context().fireClose();
    }
protected:
    void deleteMsg(Message msg, uint len)
    {
        import collie.utils.memory;
        gcFree(msg);
        if(len == 0)
        {
            _header.context().fireClose();
        }
    }
private:
    this(ContexHandler!ConsoleApplication hander){_header = hander;}
    ContexHandler!ConsoleApplication _header;
}

class ContexHandler(ConsoleApplication) : HandlerAdapter!(Message)
{
    this(shared ConsoleApplication app)
    {
        _cctx = new ConsoleContext!ConsoleApplication(this);
        _app = app;
    }
    
    final override void read(Context ctx, Message msg)
    {
        import std.conv;
        ConsoleApplication app = cast(ConsoleApplication)_app;
      //  ConsoleApplication.RouterPipeline pipe = null;
        TypeMessage tmsg = cast(TypeMessage)msg;
        if(!tmsg)
        {
            app._404(msg, _cctx);
            return;
        }
        auto pipe = app.router.match("RPC",to!string(tmsg.type));
        if (pipe is null)
        {
            app._404(msg, _cctx);
        }
        else
        {
            
            scope(exit)
            {
                import core.memory;
                pipe.destroy;
                GC.free(cast(void *)pipe);
            }
            pipe.handleActive(tmsg, _cctx);
        }
    }
    
    final override void timeOut(Context ctx)
    {
        ConsoleApplication app = cast(ConsoleApplication)_app;
        _app._timeOut(_cctx);
    }

private:
    ConsoleContext!ConsoleApplication _cctx;
    shared ConsoleApplication _app;
}

