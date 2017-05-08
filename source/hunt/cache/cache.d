module hunt.cache.cache;

import hunt.cache.driver;

import std.conv;
import std.experimental.logger;

class Cache
{
    this(string driver = "memory")
    {
        switch(driver)
        {
            case "memory":
            {
                this._cacheDriver = new MemoryCache;
            }
            version(USE_MEMCACHE)
            {
            case "memcache":
            {
                //this._cacheDriver = new MemcacheCache;
            }
            }
            version(USE_REDIS)
            {
            case "redis":
            {
                //this._cacheDriver = new RedisCache;
            }
            }
            default:
            {
                new Exception("Can't support cache driver: ", driver);
            }
        }
    }

    bool set(string key, ubyte[] value, int expire = 0)
    {
        return _cacheDriver.set(this._prefix ~ key, value, expire);
    }

    bool set(string key, string value, int expire = 0)
    {
        return _cacheDriver.set(this._prefix ~ key, cast(ubyte[])value, expire);
    }

    string get(string key)
    {
        return cast(string)_cacheDriver.get(this._prefix ~ key);
    }

	T get(T)(string key)
	{
		return cast(T)_cacheDriver.get(this._prefix ~ key);
	}

	bool isset(string key)
	{
		return _cacheDriver.isset(this._prefix ~ key);
	}

    bool erase(string key)
    {
        return _cacheDriver.erase(this._prefix ~ key);
    }

    bool flush()
    {
        return _cacheDriver.flush();
    }

    void setPrefix(string prefix)
    {
        this._prefix = prefix;
    }

    void setExpire(int expire)
    {
        this._cacheDriver.setExpire(expire);
    }

    bool init()
    {
        return this._isInit;
    }

    private
    {
        bool _isInit = false;
		string _prefix;
        AbstractCache _cacheDriver;
    }
}



unittest
{

import core.memory;
import core.atomic;
import core.thread;
import core.sync.semaphore;
import core.sync.mutex;
import core.sync.rwmutex;

import std.conv;
import std.stdio;
import std.functional;
import std.traits;
import std.typecons;
import std.typetuple;

pragma(inline) auto bind(T, Args...)(T fun, Args args) if (isCallable!(T))
{
	alias FUNTYPE = Parameters!(fun);
	static if (is(Args == void))
	{
		static if (isDelegate!T)
			return fun;
		else
			return toDelegate(fun);
	}
	else static if (FUNTYPE.length > args.length)
	{
		alias DTYPE = FUNTYPE[args.length .. $];
		return delegate(DTYPE ars) {
			TypeTuple!(FUNTYPE) value;
			value[0 .. args.length] = args[];
			value[args.length .. $] = ars[];
			return fun(value);
		};
	}
	else
	{
		return delegate() { return fun(args); };
	}
}

	__gshared Cache cache;
	cache = new Cache();
	assert(cache.set("test","test") == true);	
	assert(cache.get("test") == "test");	

	__gshared int i = 0;
	
	void tttt(int i)
	{
		writeln("set","\t",i);
		cache.set("test"~i.to!string,"test");
	}

	while(i<10) {
		new Thread(bind!(void delegate(int))(&tttt,i)).start();
		i+=1;
	}
	writeln("Thread wait...");
	Thread.sleep(5.seconds);

	foreach (m; 0 .. 10)
		writeln(m,"\t",cast(string)cache.get("test"~m.to!string));

	Thread.sleep(2.seconds);
}
