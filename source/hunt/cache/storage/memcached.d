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
module hunt.cache.storage.memcached;

import hunt.cache.storage.cache;

class MemcachedStorage : CacheStorageInterface
{
	void setPrefix(string prefix)
	{
		
	}
	
	T get(T = string)(string key, lazy T v= T.init)
	{
		return v;
	}
	
	///add a cache  expired after expires seconeds
	bool set(string key, string value, int expires)
	{
		return true;
	}
	
	///remove a cache by cache key
	bool remove(string key)
	{
		return false;
	}
}