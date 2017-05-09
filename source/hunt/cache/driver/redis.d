module hunt.cache.driver.redis;

import std.conv;

import hunt.cache.driver.base;
public import driverRedis = hunt.storage.redis;

version(USE_REDIS)
{
	class RedisCache : AbstractCache 
	{
		private int _expire;
		override bool set(string key, ubyte[] value)
		{
			return set(key,value.to!string,_expire);
		}
		override bool set(string key, ubyte[] value, int expire = 0)
		{
			return set(key,value.to!string,expire);
		}

		override bool set(string key,string value)
		{
			return driverRedis.Redis.set(key,value,_expire);	
		}
		override bool set(string key,string value,int expire = 0)
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
	}
}
