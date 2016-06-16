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

module hunt.stream.context;

import std.variant;

import collie.channel.handler;
import collie.channel.handlercontext;
import collie.channel.pipeline;

import hunt.stream.messagecoder;
import hunt.routing;

alias ConsolePipeLine = Pipeline!(ubyte[],Message);

final class ConsoleContext(ConsoleApplication)
{    
    pragma(inline)
    void write(Message msg,void delegate(Message,uint) cback = null)
    {
        if(msg is null) return;
        _header.context().fireWrite(msg,cback);
    }
    
    pragma(inline)
    void close()
    {
        _header.context().fireClose();
    }
    
    pragma(inline)
    void setData(Variant value) {_data = value;}
    pragma(inline)
    @property data() {return _data;}
private:
    this(ContexHandler!ConsoleApplication hander){_header = hander;}
    ContexHandler!ConsoleApplication _header;
    Variant _data;
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
        ConsoleApplication app = cast(ConsoleApplication)_app;
        auto cback = app.streamCallBack();
        cback(_cctx,msg);
    }
    
    final override void timeOut(Context ctx)
    {
	this.read(ctx,new TimeOutMessage());
    }
    
    final override void transportInactive(Context ctx)
    {
	this.read(ctx,new TransportInActiveMessage());
    }
    
    final override void transportActive(Context ctx)
    {
	this.read(ctx,new TransportActiveMessage());
    }

private:
    ConsoleContext!ConsoleApplication _cctx;
    shared ConsoleApplication _app;

}

