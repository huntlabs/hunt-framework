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

final class ConsoleContext
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
    this(ContexHandler hander){_header = hander;}
    ContexHandler _header;
}


abstract class ContexHandler : HandlerAdapter!(Message)
{
    this()
    {
        _cctx = new ConsoleContext(this);
    }
    
    final override void read(Context ctx, Message msg)
    {
       messageHandle(msg,_cctx);
    }
    
    final override void timeOut(Context ctx)
    {
        import std.experimental.logger;
        info("time out!");
        close(ctx);
    }
protected:
    void messageHandle(Message msg,ConsoleContext ctx);
private:
    ConsoleContext _cctx;
}

