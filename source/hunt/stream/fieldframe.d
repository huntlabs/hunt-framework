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

module hunt.stream.fieldframe;

import std.zlib;
import std.experimental.logger;

import collie.codec.lengthfieldbasedframe;
import hunt.utils.lzmahandle;

enum CompressType : ubyte
{
    NONE        = 0x00,
    ZIP         = 0x01,
    LZMA        = 0x02
}

class FieldFrame(bool littleEndian = false) : LengthFieldBasedFrame!(littleEndian)
{
    this (uint maxBody = 16384,ubyte compressType = CompressType.NONE,uint compressLevel = 6)
    {
        super(maxBody,compressType);
        _comLevel = compressLevel;
    }
    
protected:
    override ubyte[] doCompress(ref ubyte type, ubyte[] data)
    {
        if(data.length < 256 || type == CompressType.NONE)
        {
            type = CompressType.NONE;
            return data;
        }
        
        switch(type)
        {
            case CompressType.ZIP :
                data = compress(data,_comLevel);
                break;
            case CompressType.LZMA :
                data = lzmaCompress(data,_comLevel);
                break;
            default :
                type = CompressType.NONE;
                break;
        }
        if(data.ptr is null)
        {
            error("compress ERRO!");
            throw new Exception("compress ERRO!");
        }
        
        return data;
    }

    override ubyte[] unCompress(in ubyte type, ubyte[] data)
    {
        switch(type)
        {
            case CompressType.ZIP :
                data = cast(ubyte[])uncompress(data);
                break;
            case CompressType.LZMA :
                data = lzmaUnCompress(data);
                break;
            default :
                break;
        }
        if(data.ptr is null)
        {
            error("compress ERRO!");
            throw new Exception("compress ERRO!");
        }
        
        return data;
    }

    override void callBack(ubyte[] data,uint size)
    {
       // trace("write data len = ", size, " data is : ", cast(string)data);
        
        import core.memory;
        GC.free(data.ptr);
    }
    
private:
    uint _comLevel;
}