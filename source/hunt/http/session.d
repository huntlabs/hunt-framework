module hunt.http.session;

import hunt.storage;
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
	this(string driver = "file")
	{
		if(driver == string.init)driver = "file";
		this._driverName = driver;
		switch(driver)
		{
			case "memory":
				{
					this._sessionStorage = new Memory;
					break;
				}
			case "file":
				{
					this._sessionStorage = new File;
					break;
				}
				version(USE_MEMCACHE)
				{
					case "memcache":
						{
							this._sessionStorage = new Memcache;
							break;
						}
				}
				version(USE_REDIS)
				{
					case "redis":
						{
							this._sessionStorage = new Redis;
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
		return _sessionStorage.set(getRealAddr(key), cast(ubyte[])value, expire);
	}

	bool set(string key, string value)
	{
		return set(key,value,_expire);
	}

	string get(string key)
	{
		string str = cast(string)_sessionStorage.get(getRealAddr(key));
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
		return _sessionStorage.isset(getRealAddr(key));
	}

	alias del = erase;
	alias remove = erase;
	bool erase(string key)
	{
		return _sessionStorage.erase(getRealAddr(key));
	}

	bool flush()
	{
		return _sessionStorage.flush();
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
		this._sessionStorage.setExpire(expire);
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

	StorageInterface driver()
	{
		return _sessionStorage;
	}

	private
	{
		string _driverName;
		string _prefix;
		string _sessionId;
		string _path;
		string _name;
		int _expire;
		StorageInterface _sessionStorage;
	}
}
