module hunt.console.fieldframe;

import collie.codec.lengthfieldbasedframe;

enum CompressType : ubyte
{
    NONE,
    ZIP,
    GZIP,
    LZMA
}

class FieldFrame(bool littleEndian = false) : LengthFieldBasedFrame!(littleEndian)
{
    this (uint maxBody = 16384,ubyte compressType = 0x00)
    {
        super(maxBody,compressType);
    }
}