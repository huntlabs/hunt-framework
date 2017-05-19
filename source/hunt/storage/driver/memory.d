module hunt.storage.driver.memory;

import hunt.utils.time;

import std.stdio;
import std.conv;
import core.memory;
import core.sync.rwmutex;

MemoryStorage _memory;
@property MemoryInstance()
{
	if(_memory is null)
	{
		_memory = new MemoryStorage;
	}
	return  _memory;
}

class MemoryBuffer
{
    string key;
    uint length;
    ubyte[] *ptr;
    int exprie;
    MemoryBuffer prv;
    MemoryBuffer next;

    this(string key,ubyte[] value,uint length)
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

class MemoryStorage
{
    private ulong trunkNum;
    private ulong trunkSize;
    private MemoryBuffer[string] map;
    private MemoryBuffer head;
    private MemoryBuffer tail;
    private ReadWriteMutex _mutex;
    private int _exprie = 0;
    private int _counter;
    //cache check valid cycle
    private int _checkValidCycle = 100000;

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

    bool set(string key, ubyte[] value, int exprie)
    {
        //if(isset(key))return false;
        _mutex.writer.lock();
        scope(exit) _mutex.writer.unlock();

        if(exprie < 0)exprie = 0;

        auto trunk = new MemoryBuffer(key,value,value.length.to!uint);
        trunk.exprie = ((exprie == 0) ? 0 : (getCurrUnixStramp + exprie));
        writeln(trunk.exprie,cast(string)(*trunk.ptr));

        if(isset(key)){
            trunkSize = trunkSize + value.length - map[key].length;
            if(map[key].prv)trunk.prv = map[key].prv;
            if(map[key].next)trunk.next = map[key].next;
            map[key] = trunk;
        }else{
            trunkNum++;
            trunkSize+=value.length;
            
            map[key] = trunk;

            if(head is MemoryBuffer.init){
                head = trunk;
                tail = trunk;
            }else{
                tail.next = trunk;
                trunk.prv = tail;
                tail = trunk;
            }
        }

        return true;
    }

    bool set(string key,ubyte[] value)
    {
        return set(key,value,_exprie);
    }
    bool set(string key,string value)
    {
        return set(key,cast(ubyte[])value,_exprie);
    }
    bool set(string key,string value,int exprie)
    {
        return set(key,cast(ubyte[])value,exprie);
    }

    T get(T)(string key)
    {
        return cast(T)get(key);
    }

    string get(string key)
    {
        if(!isset(key))return null;
        if(!isExpire(key)){
            return null;
        }
        _mutex.reader.lock();
        scope(exit) _mutex.reader.unlock();
        return cast(string)(*(map[key].ptr));
    }

    bool isset(string key)
    {
        if(map.get(key,null) is null)return false;
        return true;
    }

    bool erase(string key)
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

    bool flush()
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

    void setExpire(int exprie)
    {
        this._exprie = exprie;
    }

    private bool isExpire(string key)
    {
        writeln(map[key].exprie);
        if(map[key].exprie == 0)return true;
        if(map[key].exprie <= getCurrUnixStramp)
        {
            scope(exit)erase(key);
            return false;
        }else{
            return true;
        }

    }

    private void counter()
    {
        _counter++;
        if(_counter >= _checkValidCycle){
            foreach(k,v;map)
            {
                isExpire(k);
            }
            _counter = 0;
        }
    }

    void setDefaultHost(string host,ushort port)
    {
    }
}

unittest
{
    import std.stdio;
    import core.thread;
    auto memory = new MemoryStorage();
    string test = "test";
    ubyte[] utest = cast(ubyte[])test;
    memory.set(test,utest);
    assert(memory.getTrunkNum == 1);
    assert(memory.getTrunkSize == utest.length);
    assert(memory.get(test) == test);
    string test2 = "testasdfasjdflkjaklsdjfl";
    ubyte[] utest2 = cast(ubyte[])test2;
    memory.set(test2,utest2);
    assert(memory.getTrunkNum == 2);
    assert(memory.getTrunkSize == utest.length + utest2.length);
    assert(memory.get(test2) == test2);
    assert(memory.get("testsdfadf") == null);
    memory.erase(test2);
    assert(memory.getTrunkNum == 1);
    assert(memory.getTrunkSize == utest.length);
    memory.flush();
    assert(memory.getTrunkNum == 0);

    assert(memory.set(test,utest) == true);
    assert(memory.getTrunkNum == 1);
    assert(memory.getTrunkSize == utest.length);
    assert(memory.set(test,utest2) == true);
    assert(memory.getTrunkNum == 1);
    assert(memory.getTrunkSize == utest2.length);
    memory.flush();

    memory.setExpire = 5;
    assert(memory.set(test,utest,0) == true);
    assert(memory.set(test2,utest) == true);

    assert(memory.getTrunkNum == 2);
    assert(memory.getTrunkSize == utest.length + utest.length);

    writeln("wait timeout");
    Thread.sleep(6.seconds);
    writeln("timeout");

    assert(memory.get(test2) == null);
    assert(memory.getTrunkNum == 1);
    assert(memory.getTrunkSize == utest.length);
}
