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
 
module hunt.stream.messagecoder;

import std.bitmanip;
import std.experimental.logger;

//import collie.channel;
import collie.channel.handler;
import collie.channel.handlercontext;

interface Message
{
    string type();
    ubyte[] encodeMeassage();
}

final class TimeOutMessage : Message
{
    override string type() {return "TimeOut";}
    override ubyte[] encodeMeassage() {return null;}
}

final class TransportActiveMessage : Message
{
    override string type() {return "TransportActive";}
    override ubyte[] encodeMeassage() {return null;}
}

final class TransportInActiveMessage : Message
{
    override string type() {return "TransportInActive";}
    override ubyte[] encodeMeassage() {return null;}
}

interface CryptHandler
{
    ubyte[] encrypt(ubyte[]);
    ubyte[] decrypt(ubyte[]);
    
    CryptHandler copy() const shared;
}

interface MessageDecode
{
    Message decode(ubyte[]) shared;
}

final class NoCrypt : CryptHandler
{
    override ubyte[] encrypt(ubyte[] data){return data;}
    override ubyte[] decrypt(ubyte[] data){return data;}
    
    override CryptHandler copy() const shared
    {
        return new NoCrypt;
    }
}

class MessageCoder : Handler!(ubyte[], Message, Message, ubyte[])
{
    this(shared MessageDecode decoder,CryptHandler crypt = new NoCrypt())
    {
        _crypt = crypt;
        _dcoder = decoder;
    }
    
    override void read(Context ctx, ubyte[] msg)
    {
        auto data = _crypt.decrypt(msg);
        if(data.ptr is null){
            error("decrypt Meassage erro!");
            ctx.fireRead(null);
            return;
        }
        auto mesg =  _dcoder.decode(data);
        ctx.fireRead(mesg);
    }
    
    override void write(Context ctx, Message msg, TheCallBack cback = null)
    {
        auto data = msg.encodeMeassage();
        data = _crypt.encrypt(data);
        if(data.ptr is null && cback)
        {
            cback(msg,0);
            error("encrypt Meassage erro!");
            return;
        }
        ctx.fireWrite(data,&callBack);
        if(cback) cback(msg,cast(uint)(data.length));
    }
    
protected:
    void callBack(ubyte[] data, uint len)
    {
        import core.memory;
        GC.free(data.ptr);
    }
private:
    CryptHandler _crypt;
    shared MessageDecode _dcoder;
}