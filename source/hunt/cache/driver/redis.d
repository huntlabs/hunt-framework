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

module hunt.cache.driver.redis;

import std.conv;
import std.stdio;
import std.experimental.logger;

import hunt.cache.driver.base;
public import driverRedis = hunt.storage.redis;

version(USE_REDIS)
{
	class RedisCache : AbstractCache 
	{
		private int _expire = 3600 * 24 * 365;
		override bool set(string key, ubyte[] value)
		{
			return set(key,value,_expire);
		}
		override bool set(string key, ubyte[] value, int expire)
		{
			return driverRedis.Redis.set(key,cast(string)value,expire);
		}

		override bool set(string key,string value)
		{
			return set(key,value,_expire);	
		}
		override bool set(string key,string value,int expire)
		{
			return driverRedis.Redis.set(key,value,expire);	
		}

		T get(T)(string key)
		{
			return cast(T)driverRedis.Redis.get(key);
		}
		override string get(string key)
		{
			return driverRedis.Redis.get(key);
		}

		override bool isset(string key)
		{
			return driverRedis.Redis.exists(key);
		}

		override bool erase(string key)
		{
			return cast(bool)driverRedis.Redis.del(key);
		}

		override bool flush()
		{
			driverRedis.Redis.flushall();
			return true;
		}

		override void setExpire(int expire)
		{
			this._expire = expire;
		}

		auto opDispatch(string name,T...)(T args)
		{
			auto result =  driverRedis.Redis.send(name,args);
			return result;
		}
		override void setDefaultHost(string host , ushort port)
		{
			driverRedis.setDefaultHost(host,port);
		}
	}
}
