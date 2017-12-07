module hunt.cache.cache;

import hunt.storage;

import std.conv;
import core.sync.rwmutex;
import std.experimental.logger;

class Cache
{
    private ReadWriteMutex _mutex;
    this(string driver = "memory")
    {
        switch(driver)
        {
			case "memory":
			{
				this._cacheStorage = new Memory;
				break;
			}
			case "file":
			{
				this._cacheStorage = new File;
				break;
			}
			version(USE_MEMCACHE)
			{
				case "memcache":
				{
					this._cacheStorage = new Memcache;
					break;
				}
			}
			version(USE_REDIS)
			{
				case "redis":
				{
					this._cacheStorage = new Redis;
					break;
				}
			}
			default:
			{
				throw new Exception("Can't support cache driver: ", driver);
			}
        }
        
        _mutex = new ReadWriteMutex();
    }

    ~this()
    {
        _mutex.destroy();
    }

    bool set(T)(string key,T value , int expire = 0)
    {
        _mutex.writer.lock();
        scope(exit) _mutex.writer.unlock();
        return _cacheStorage.set(this._prefix ~ key, value, expire == 0 ? this.expire : expire);
    }

    string get(string key)
    {
        _mutex.writer.lock();
        scope(exit) _mutex.writer.unlock();
        return cast(string)_cacheStorage.get(this._prefix ~ key);
    }

    T get(T)(string key)
    {
        _mutex.writer.lock();
        scope(exit) _mutex.writer.unlock();
        return cast(T)_cacheStorage.get(this._prefix ~ key);
    }

    bool isset(string key)
    {
        return _cacheStorage.isset(this._prefix ~ key);
    }

    bool erase(string key)
    {
        return _cacheStorage.erase(this._prefix ~ key);
    }

    bool flush()
    {
        return _cacheStorage.flush();
    }

    void setPrefix(string prefix)
    {
        this._prefix = prefix;
    }

    void setExpire(int expire)
    {
        this._expire = expire;
        this._cacheStorage.setExpire(expire);
    }

    int expire()
    {
        return _expire;
    }

    StorageInterface driver()
    {
        return _cacheStorage;
    }

    private
    {
        string _prefix;
        int _expire;
        StorageInterface _cacheStorage;
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
    writeln(cache.driver);
    assert(cache.set("test","test") == true);    
    writeln(cache.get("test"));
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
