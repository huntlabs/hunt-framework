/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.cache.driver.memcache;

import std.conv;

import hunt.cache.driver.base;
public import driverMemcached = hunt.storage.memcached;

version(USE_MEMCACHE)
{
	class MemcacheCache : AbstractCache 
	{
		private int _expire = 3600 * 24 * 365;
		override bool set(string key, ubyte[] value, int expire)
		{
			return set(key,value.to!string,expire);
		}

		override bool set(string key,string value,int expire)
		{
			return driverMemcached.Memcache.set(key,value,expire);	
		}
		
		override bool set(string key, ubyte[] value)
		{
			return set(key,value,_expire);
		}

		override bool set(string key,string value)
		{
			return set(key,value,_expire);	
		}

		override string get(string key)
		{
			return cast(string)driverMemcached.Memcache.get(key);
		}

		T get(T)(string key)
		{
			return cast(T)driverMemcached.Memcache.get(key);
		}

		override bool isset(string key)
		{
			return false;	
		}

		override bool erase(string key)
		{
			return false;
		}

		override bool flush()
		{
			return false;
		}

		override void setExpire(int expire)
		{
			this._expire = expire;
		}
		auto opDispatch(string name,T...)(T args)
		{
			return null;
		}
		override void setDefaultHost(string host, ushort port)
		{
			driverMemcached.setDefaultHost(host,port);
		}
	}
}
