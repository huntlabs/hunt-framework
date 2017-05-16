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
		if (driver == string.init)
		{
			driver = "memory";
		}
		
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

	bool set(string key, string value, int expire)
	{
		return _cacheDriver.set(getRealAddr(key), cast(ubyte[])value, expire);
	}

	bool set(string key, string value)
	{
		return set(key,value,_expire);
	}

	string get(string key)
	{
		string str = cast(string)_cacheDriver.get(getRealAddr(key));
		if("_driverName" == "file"){
			JSONValue js = parseJSON(str);
			if(js["_time"].integer <= getCurrUnixStramp){
				erase(key);
				return null;
			}
		}
		return str;
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
