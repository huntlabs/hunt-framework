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
    ubyte[] encodeMeassage(bool litteEndian);
}

interface CryptHandler
{
    ubyte[] encrypt(ubyte[]);
    ubyte[] decrypt(ubyte[]);
    
    CryptHandler copy() const shared;
}


final class TypeMessage : Message
{
    this(){}
    this(ushort type, ubyte[] data)
    {
        this.type = type;
        this.data = data;
    }
    
    ushort type;
    ubyte[] data;

    override string getType(){return TypeMessage.stringof;}
    
    override ubyte[] encodeMeassage(bool litteEndian) 
    {
        ubyte[] data = new ubyte[data.length + 2];
        ubyte[2] tdata;
        if (litteEndian)
            tdata = nativeToLittleEndian(type); 
        else
            tdata = nativeToBigEndian(type); 
        data[0..2] = tdata[];
        data[2..$] = data[];
        return data;
    }
    
    static TypeMessage decodeMeassage(bool litteEndian, bool copy = false)(ubyte[] data)
    {
        if(data.length < 2) return null;
        TypeMessage msg = new TypeMessage();
        ubyte[2] type = data[0..2];
        static if (litteEndian)
            msg.type = littleEndianToNative!ushort(type); //littleEndianToNative
        else
            msg.type = bigEndianToNative!ushort(type); 
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
    
    override CryptHandler copy() const shared
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
        auto mesg =  TypeMessage.decodeMeassage!(litteEndian,false)(msg);
        if(mesg)
            ctx.fireRead(mesg);
    }
    
    override void write(Context ctx, Message msg, TheCallBack cback = null)
    {
        auto data = msg.encodeMeassage(litteEndian);
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