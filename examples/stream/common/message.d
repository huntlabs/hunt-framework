module message;

import hunt.stream.messagecoder;

import std.bitmanip;
import std.stdio;

enum MSGType :ushort
{
    BEAT = 2,
    DATA = 1
}


final class BeatMessage : Message
{
    ubyte[] data;

    override string type(){return MSGType.BEAT.stringof;}
    
    override ubyte[] encodeMeassage()  
    {
        ubyte[] tdata = new ubyte[data.length + 2];
        ubyte[2] dtype = nativeToBigEndian(cast(ushort)MSGType.BEAT); 
        tdata[0..2] = dtype[];
        tdata[2..$] = data[];
        return tdata;
    }
    
    static Message decodeMeassage(ubyte[] data)
    {
        BeatMessage msg = new BeatMessage();
        msg.data = data;
        return msg;
    }
}

class DataMessage : Message
{
    override string type(){return MSGType.DATA.stringof;}
    override ubyte[] encodeMeassage()
    {
        ubyte[] data = new ubyte[30];
        ubyte[2] dtype = nativeToBigEndian(cast(ushort)MSGType.DATA);
        data[0..2] = dtype[];
        ubyte[4] cdata = nativeToBigEndian(commod);
        data[2..6] = cdata[];
        ubyte[8] fdata;
        fdata = nativeToBigEndian(fvalue);
        data[6..14] = fdata[];
        fdata = nativeToBigEndian(svalue);
        data[14..22] = fdata[];
        fdata = nativeToBigEndian(value);
        data[22..$] = fdata;
        return data;
    }
    
    uint commod;
    long fvalue;
    long svalue;
    
    long value;
    
    static Message decodeMeassage(ubyte[] data)
    {
        if(data.length < 28) return null;
        DataMessage msg = new DataMessage();
        ubyte[4] cdata = data[0..4];
        msg.commod = bigEndianToNative!uint(cdata); //
        
        ubyte[8] fdata = data[4..12];
        msg.fvalue = bigEndianToNative!long(fdata); //
        fdata = data[12..20];
        msg.svalue = bigEndianToNative!long(fdata); //
        fdata = data[20..$];
        msg.value = bigEndianToNative!long(fdata); //
        return msg;
    }
}


class MyDecode :  MessageDecode
{
    override Message decode(ubyte[] data) shared
    {
        ubyte[2] dtype  = data[0..2];
        data = data[2..$];
        writeln("type is : ",dtype);
        ushort type = bigEndianToNative!ushort(dtype); //
        writeln("decode data , type is : ",type);
        switch(type)
        {
            case MSGType.BEAT:
                return BeatMessage.decodeMeassage(data);
            case MSGType.DATA:
                return DataMessage.decodeMeassage(data);
            default:
                return null;
        }
    }
}
