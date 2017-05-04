module hunt.cache.buffertrunk;

import hunt.cache;

class BufferTrunk
{
	string key;
	ulong length;
	ubyte[] *ptr;
	BufferTrunk prv;
	BufferTrunk next;
	this(string key,ubyte[] value,ulong length)
	{
		this.key = key;
		this.length = length;
		ptr = cast(ubyte[] *)GC.malloc(length);
		*ptr = value;
	}
	void clean()
	{
		length = 0;
		GC.free(ptr);
	}
	~this()
	{
		if(length)GC.free(ptr);
	}
}
