module hunt.cache.cache;

import hunt.cache;

class Cache
{
	Store _store;

	this(Store store)
	{
		this._store = store;
	}

	bool set(string key,ubyte[] value)
	{
		return _store.set(key,value);		
	}
	bool set(string key,string value)
	{
		return set(key,cast(ubyte[])value);
	}

	ubyte[] get(string key)
	{
		return _store.get(key);
	}
	T get(T)(string key)
	{
		return cast(T)_store.get(key);
	}

	bool remove(string key)
	{
		return _store.remove(key);
	}

	bool isset(string key)
	{
		return _store.isset(key);
	}

	void clean()
	{
		_store.clean();
	}
}

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

unittest
{
	__gshared Store store;
	__gshared Cache cache;
	store = new Memory();
	cache = new Cache(store);
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
	writeln("fuck...");
	Thread.sleep(10.seconds);

	foreach (m; 0 .. 10)
		writeln(m,"\t",cast(string)cache.get("test"~m.to!string));

	Thread.sleep(20.seconds);
}
