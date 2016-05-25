module message;

import hunt.console.messagecoder;

import std.bitmanip;

class MyMessage : Message
{
    string getType(){return MyMessage.stringof;}
    ubyte[] encodeMeassage(bool litteEndian)
    {
        ubyte[] data = new ubyte[28];
        ubyte[4] cdata;
        if (litteEndian)
            cdata = nativeToLittleEndian(commod);
        else
            cdata = nativeToBigEndian(commod);
        data[0..4] = cdata[];
        ubyte[8] fdata;
        if (litteEndian)
            data = nativeToLittleEndian(fvalue);
        else
            fdata = nativeToBigEndian(fvalue);
        data[4..12] = fdata[];
        if (litteEndian)
            fdata = nativeToLittleEndian(svalue);
        else
            fdata = nativeToBigEndian(svalue);
        data[12..20] = fdata[];
        if (litteEndian)
            fdata = nativeToLittleEndian(value);
        else
            fdata = nativeToBigEndian(value);
        data[20..$] = fdata;
        return data;
    }
    
    uint commod;
    double fvalue;
    double svalue;
    
    double value;
    
    static MyMessage decodeMeassage(bool littleEndian)(ubyte[] data)
    {
        if(data.length != 28) return null;
        MyMessage msg = new MyMessage();
        ubyte[4] cdata = data[0..4];
        
        static if (littleEndian)
            msg.commod = littleEndianToNative!uint(cdata); //littleEndianToNative
        else
            msg.commod = bigEndianToNative!uint(cdata); //
        
        ubyte[8] fdata = data[4..12];
        static if (littleEndian)
            msg.fvalue = littleEndianToNative!double(fdata); //littleEndianToNative
        else
            msg.fvalue = bigEndianToNative!double(fdata); //
        fdata = data[12..20];
        static if (littleEndian)
            msg.svalue = littleEndianToNative!double(fdata); //littleEndianToNative
        else
            msg.svalue = bigEndianToNative!double(fdata); //
        fdata = data[20..$];
        static if (littleEndian)
            msg.value = littleEndianToNative!double(fdata); //littleEndianToNative
        else
            msg.value = bigEndianToNative!double(fdata); //
        return msg;
    }
}
