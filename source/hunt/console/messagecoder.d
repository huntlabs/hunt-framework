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
 
module hunt.console.messagecoder;

import std.bitmanip;

//import collie.channel;
import collie.channel.handler;
import collie.channel.handlercontext;

interface Message
{

    string getType();
    ubyte[] encodeMeassage(bool litteEndian)();
}

interface CryptHandler
{
    ubyte[] encrypt(ubyte[]);
    ubyte[] decrypt(ubyte[]);
    
    CryptHandler copy() const;
}


final class TypeMessage : Message
{
    this(ushort type, ubyte[] data)
    {
        this.type = type;
        this.data = data;
    }
    
    ushort type;
    ubyte[] data;

    override string getType(){return TypeMessage.stringof;}
    
    override ubyte[] encodeMeassage(bool litteEndian)()  
    {
        ubyte[] data = new ubyte[msg.data.length + 2];
        static if (littleEndian)
        {
            ubyte[2] type = nativeToLittleEndian(msg.type); 
        }
        else
        {
            ubyte[2] type = nativeToBigEndian(msg.type); 
        }
        data[0..2] = type[];
        data[2..$] = msg.data[];
        return data;
    }
    
    static Message decodeMeassage(bool litteEndian, bool copy = false)(ubyte[] data)
    {
        if(data.length < 2) return null;
        Message msg = new Message();
        ubyte[2] type = data[0..2];
        static if (littleEndian)
        {
            msg.type = littleEndianToNative!ushort(type); //littleEndianToNative
        }
        else
        {
            msg.type = bigEndianToNative!ushort(type); //
        }
        static if(copy)
            msg.data = data[2..$].dup;   
        else
            msg.data = data[2..$];
        return msg;
    }
}


final class NoCrypt : CryptHandler
{
    override ubyte[] encrypt(ubyte[] data){return data;}
    override ubyte[] decrypt(ubyte[] data){return data;}
    
    override CryptHandler copy() const
    {
        return new NoCrypt;
    }
}

class MessageCoder(bool litteEndian = false) : Handler!(ubyte[], Message, Message, ubyte[])
{
    this(CryptHandler crypt = new NoCrypt())
    {
        _crypt = crypt;
    }
    
    override void read(Context ctx, ubyte[] msg)
    {
        auto data = _crypt.decrypt(msg);
        if(data.ptr is null) return;
        auto mesg =  Message.decodeMeassage!(litteEndian,false)(msg);
        if(mesg)
            ctx.fireRead(mesg);
    }
    
    override void write(Context ctx, Message msg, TheCallBack cback = null)
    {
        auto data = msg.encodeMeassage!(litteEndian)();
        data = _crypt.encrypt(data);
        if(data.ptr is null && cback) cback(msg,0);
        ctx.fireWrite(data,&callBack);
        if(cback) cback(msg,cast(uint)(data.length));
    }
    
    //override void timeOut(Context ctx) {}
    
protected:
    void callBack(ubyte[] data, uint len)
    {
        import core.memory;
        GC.free(data.ptr);
    }
private:
    CryptHandler _crypt;
}