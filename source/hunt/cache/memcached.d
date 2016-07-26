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
module hunt.cache.memcached;

import hunt.storage.memcached;
import hunt.cache.base;

class MemcachedCache : Cache
{
	static @property defaultCahe()
	{
		if(_storage is null)
		{
			_storage = new MemcachedCache(theMemcache);
		}
		return _storage;
	}

	this(Memcache memcahe)
	{
		_mcache = memcahe;
	}

	T getByKey(T = string)(string master_key,string key, lazy T v= T.init)
	{
		if(master_key.length > 0)
		{
			return _mcache.getByKey!T(master_key,key,v);
		}
		else
		{
			return _mcache.get!T(key,v);
		}
	}
	///add a cache  expired after expires seconeds
	override bool setByKey(string master_key,string key, string value, int expires)
	{
		if(master_key.length > 0)
		{
			return _mcache.setByKey!string(master_key,key,value,expires);
		}
		else
		{
			return _mcache.set!string(key,value,expires);
		}
	}
	
	///remove a cache by cache key
	override bool removeByKey(string master_key,string key)
	{
		if(master_key.length > 0)
		{
			return _mcache.delByKey(master_key,key);
		}
		else
		{
			return _mcache.del(key);
		}
	}

private:
	static MemcachedCache _storage;
	Memcache _mcache;
}
