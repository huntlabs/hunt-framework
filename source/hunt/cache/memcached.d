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
import std.experimental.logger;
import std.string;
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

	override string getByKey(string master_key,string key, lazy string v= string.init)
	{
		if(master_key.length > 0)
		{
			return _mcache.getByKey!string(packString(master_key),packString(key),v);
		}
		else
		{
			auto xx = _mcache.get!string(packString(key),v);
			info("memcached....", xx);
			return xx;
		}
	}
	///add a cache  expired after expires seconeds
	override bool setByKey(string master_key,string key, string value, int expires)
	{
		if(master_key.length > 0)
		{
			return _mcache.setByKey!string(packString(master_key),packString(key),value,expires);
		}
		else
		{
			return _mcache.set!string(packString(key),value,expires);
		}
	}
	
	///remove a cache by cache key
	override bool removeByKey(string master_key,string key)
	{
		if(master_key.length > 0)
		{
			return _mcache.delByKey(packString(master_key),packString(key));
		}
		else
		{
			return _mcache.del(packString(key));
		}
	}

	private string packString(string t)
	{
		info("memcache packstring:",  t);
		//return "\"" ~ t ~ "\"";
		return t.replace(" ", "+");
	}

private:
	static MemcachedCache _storage;
	Memcache _mcache;
}
