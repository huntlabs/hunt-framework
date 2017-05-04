module hunt.cache.memory;

import hunt.cache;

class Memory : Store
{
	private ulong trunkNum;
	private ulong trunkSize;
	private BufferTrunk[string] map;
	private BufferTrunk head;
	private BufferTrunk tail;
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
	override bool set(string key,ubyte[] value)
	{
		if(isset(key))return false;
		_mutex.writer.lock();
		scope(exit) _mutex.writer.unlock();
		BufferTrunk trunk = new BufferTrunk(key,value,value.length);
		map[key] = trunk;
		trunkNum++;
		trunkSize+=value.length;
		if(head is BufferTrunk.init){
			head = trunk;
			tail = trunk;
		}else{
			tail.next = trunk;
			trunk.prv = tail;
			tail = trunk;
		}
		return true;
	}
	override ubyte[]  get(string key)
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
	override bool remove(string key)
	{
		_mutex.writer.lock();
		scope(exit) _mutex.writer.unlock();
		if(!isset(key))return true;
		if(map[key].prv)map[key].prv.next = map[key].next;
		if(map[key].next)map[key].next.prv = map[key].prv;
		trunkNum--;
		trunkSize-=map[key].length;
		map[key].clean();
		map[key].destroy();
		map.remove(key);
		return true;
	}
	override void clean()
	{
		foreach(k,v;map){
			v.clean();
			v.destroy();
			map.remove(k);
		}
		map.destroy();
		trunkNum = 0;
		trunkSize = 0;
		head = null;
		tail = null;
	}
}

unittest
{
	import std.stdio;
	Memory memory = new Memory();
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
	memory.remove(test2);
	assert(memory.getTrunkNum == 1);
	assert(memory.getTrunkSize == utest.length);
	memory.clean();
	assert(memory.getTrunkNum == 0);
}
