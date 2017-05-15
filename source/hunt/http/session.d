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

module hunt.http.session;
import hunt.cache.driver;
import hunt.utils.time;

import std.json;
import std.conv;
import std.digest.sha;
import std.format;
import std.datetime;
import std.random;
import core.cpuid;
import std.string;
import std.experimental.logger;

class Session
{
	this(string driver = "memory")
	{
		this._driverName = driver;
		switch(driver)
		{
			case "memory":
				{
					this._cacheDriver = new MemoryCache;
					break;
				}
			case "file":
				{
					this._cacheDriver = new FileCache;
					break;
				}
				version(USE_MEMCACHE)
				{
					case "memcache":
						{
							this._cacheDriver = new MemcacheCache;
							break;
						}
				}
				version(USE_REDIS)
				{
					case "redis":
						{
							this._cacheDriver = new RedisCache;
							break;
						}
				}
			default:
				{
					new Exception("Can't support cache driver: ", driver);
				}
		}
	}

	string generateSessionId(string sessionName = "hunt_session")
	{
		auto str = toHexString(sha1Of(format("%s--%s--%s",
						Clock.currTime().toISOExtString, uniform(long.min, long.max), processor())));

		auto sstr = toLower(cast(string)(str[]));
		
		JSONValue json;
		json[sessionName] = sstr;
		json["_time"] = getCurrUnixStramp; 

		set(sstr,json.toString,_expire);

		return sstr;
	}

	/*
	void setId(string id)
	{
		this._sessionId = id;
	}
	string getId()
	{
		if(!_sessionId.length)
			_sessionId = generateSessionId();
		return _sessionId;
	}
	*/

	bool set(string key, ubyte[] value, int expire)
	{
		return _cacheDriver.set(getRealAddr(key), value, expire);
	}

	bool set(string key, ubyte[] value)
	{
		return set(key, value, expire);
	}

	bool set(string key, string value, int expire)
	{
		return _cacheDriver.set(getRealAddr(key), cast(ubyte[])value, expire);
	}

	bool set(string key, string value)
	{
		return set(key,value, expire);
	}

	string get(string key)
	{
		return cast(string)_cacheDriver.get(getRealAddr(key));
	}

	T get(T)(string key)
	{
		return cast(T)get(key);
	}

	bool isset(string key)
	{
		return _cacheDriver.isset(getRealAddr(key));
	}

	alias del = erase;
	alias remove = erase;
	bool erase(string key)
	{
		return _cacheDriver.erase(getRealAddr(key));
	}

	bool flush()
	{
		return _cacheDriver.flush();
	}

	void setPrefix(string prefix)
	{
		this._prefix = prefix;
	}

	void setPath(string path)
	{
		this._path = path;
	}

	void setExpire(int expire)
	{
		this._expire = expire;
		this._cacheDriver.setExpire(expire);
	}

	string getRealAddr(string key)
	{
		if(_driverName == "file")
		{
			return _path ~ _prefix ~ key;
		}
		return _prefix ~ key;
	}
	int expire()
	{
		return _expire;
	}

	AbstractCache driver()
	{
		return _cacheDriver;
	}

	private
	{
		string _driverName;
		string _prefix;
		string _sessionId;
		string _path;
		string _name;
		int _expire;
		AbstractCache _cacheDriver;
	}
}
