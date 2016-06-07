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

module hunt.utils.lzmahandle;

version(LZMA_COMPRESS) import deimos.lzma;


ubyte[] lzmaCompress(ubyte[] data, uint level)
{
    version(LZMA_COMPRESS)
    {
        import collie.utils.vector;
        lzma_stream strm = lzma_stream.init; /* alloc and init lzma_stream struct */
        lzma_ret ret_xz = lzma_easy_encoder (&strm, level, lzma_check.LZMA_CHECK_CRC64);
        if (ret_xz != lzma_ret.LZMA_OK)
        {
            return null;
        }
        scope(exit) lzma_end(&strm);
        
        ubyte[1024] out_buf;
        strm.next_in = data.ptr;
        strm.avail_in = data.length;
        size_t out_len;
        
        Vector!(ubyte) rdata;
        
        do
        {
            /* out_buf is clean at this point */
            strm.next_out = out_buf.ptr;
            strm.avail_out = out_buf.length;

            /* compress data */
            ret_xz = lzma_code (&strm, lzma_action.LZMA_FINISH);

            if ((ret_xz == lzma_ret.LZMA_OK) || (ret_xz == lzma_ret.LZMA_STREAM_END))
            {
                 /* write compressed data */
                out_len = out_buf.length - strm.avail_out;
                rdata.insertBack(out_buf[0 .. out_len]);
            }
            else
            {
               return null;
            }
        }
        while (strm.avail_out == 0);
        
        return rdata.data(true);
        
    }
    else
    {
        return data;
    }
}

ubyte[] lzmaUnCompress(ubyte[] data)
{
    version(LZMA_COMPRESS)
    {
        import collie.utils.vector;
        uint flags = LZMA_TELL_UNSUPPORTED_CHECK | LZMA_CONCATENATED;
        lzma_stream strm = lzma_stream.init; /* alloc and init lzma_stream struct */
        lzma_ret ret_xz = lzma_stream_decoder (&strm, ulong.max, flags);
        if (ret_xz != lzma_ret.LZMA_OK)
        {
            return null;
        }
        scope(exit) lzma_end(&strm);
        
        ubyte[1024] out_buf;
        strm.next_in = data.ptr;
        strm.avail_in = data.length;
        size_t out_len;
        
        Vector!(ubyte) rdata;
        
        do
        {
            /* out_buf is clean at this point */
            strm.next_out = out_buf.ptr;
            strm.avail_out = out_buf.length;

            /* compress data */
            ret_xz = lzma_code (&strm, lzma_action.LZMA_FINISH);

            if ((ret_xz == lzma_ret.LZMA_OK) || (ret_xz == lzma_ret.LZMA_STREAM_END))
            {
                 /* write compressed data */
                out_len = out_buf.length - strm.avail_out;
                rdata.insertBack(out_buf[0 .. out_len]);
            }
            else
            {
               return null;
            }
        }
        while (strm.avail_out == 0);
        
        return rdata.data(true);
        
    }
    else
    {
        return data;
    }
}


unittest
{
version(LZMA_COMPRESS) {
    import std.stdio;

    ubyte[] data = cast(ubyte[])(q{"44444444444444444444444444555555555555555556666666666666
                                        6666666666465854saqewddddddddddddd46555555555555555514546541
                                        6546516546sadfcdzsretgdrftggggggggggggggggggggggggg4
                                        tgubyhijokpl[;fyvbughijopk[l;]'ftyguijopk[-l;]"});
    writeln("the data length: ", data.length);
    ubyte[] cdata = lzmaCompress(data);
    writeln("after compress data length : ", cdata.length);
    ubyte[] udata = lzmaUnCompress(cdata);
    writeln("after uncompress data length: ", udata.length);
    assert(data == udata);
}
}
