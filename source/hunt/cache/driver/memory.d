module hunt.cache.driver.memory;

import hunt.cache.driver.base;

import core.memory;
import core.sync.rwmutex;

class MemoryBuffer
{
	string key;
	ulong length;
	ubyte[] *ptr;
	MemoryBuffer prv;
	MemoryBuffer next;

	this(string key,ubyte[] value,ulong length)
	{
		this.key = key;
		this.length = length;
		ptr = cast(ubyte[] *)GC.malloc(length);
		*ptr = value;
	}

	void clear()
	{
		length = 0;
		GC.free(ptr);
	}

	~this()
	{
		if(length)GC.free(ptr);
	}
}

class MemoryCache : AbstractCache
{
	private ulong trunkNum;
	private ulong trunkSize;
	private MemoryBuffer[string] map;
	private MemoryBuffer head;
	private MemoryBuffer tail;
	private ReadWriteMutex _mutex;

	this()
	{
		_mutex = new ReadWriteMutex();
	}

	~this()
	{
		_mutex.destroy();
	}

	ulong getTrunkNum()
	{
		return trunkNum;
	}

	ulong getTrunkSize()
	{
		return trunkSize;
	}

	override bool set(string key, ubyte[] value, int exprie = 0)
	{
		if(isset(key))return false;

		_mutex.writer.lock();
		scope(exit) _mutex.writer.unlock();

		auto trunk = new MemoryBuffer(key,value,value.length);

		map[key] = trunk;
		trunkNum++;
		trunkSize+=value.length;
        
		if(head is MemoryBuffer.init){
			head = trunk;
			tail = trunk;
		}else{
			tail.next = trunk;
			trunk.prv = tail;
			tail = trunk;
		}

		return true;
	}

	override ubyte[] get(string key)
	{
		_mutex.reader.lock();
		scope(exit) _mutex.reader.unlock();

		return map.get(key,null) ? *(map[key].ptr) : null;
	}
    
	override bool isset(string key)
	{
		if(map.get(key,null) is null) 
			return false;

		return true;
	}

	override bool erase(string key)
	{
		_mutex.writer.lock();
		scope(exit) _mutex.writer.unlock();

		if(!isset(key))return true;

		if(map[key].prv)map[key].prv.next = map[key].next;
		if(map[key].next)map[key].next.prv = map[key].prv;

		trunkNum--;
		trunkSize-=map[key].length;
        
		map[key].clear();
		map[key].destroy();
		map.remove(key);

		return true;
	}

	override bool flush()
	{
		foreach(k,v;map)
        {
			v.clear();
			v.destroy();
			map.remove(k);
		}

		map.destroy();
		trunkNum = 0;
		trunkSize = 0;
		head = null;
		tail = null;

        return true;
	}
}

unittest
{
	import std.stdio;
	auto memory = new MemoryCache();
	string test = "test";
	ubyte[] utest = cast(ubyte[])test;
	memory.set(test,utest);
	assert(memory.getTrunkNum == 1);
	assert(memory.getTrunkSize == utest.length);
	assert(memory.get(test) == utest);
	string test2 = "testasdfasjdflkjaklsdjfl";
	ubyte[] utest2 = cast(ubyte[])test2;
	memory.set(test2,utest2);
	assert(memory.getTrunkNum == 2);
	assert(memory.getTrunkSize == utest.length + utest2.length);
	assert(memory.get(test2) == utest2);
	assert(memory.get("testsdfadf") == null);
	memory.erase(test2);
	assert(memory.getTrunkNum == 1);
	assert(memory.getTrunkSize == utest.length);
	memory.flush();
	assert(memory.getTrunkNum == 0);
}
