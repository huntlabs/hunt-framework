module hunt.http.session;

import huntlabs.cache;
import hunt.utils.time;

import std.json;
import std.conv;
import std.digest.sha;
import std.format;
import std.datetime;
import std.random;
import core.cpuid;
import std.string;
import kiss.log;

class Session
{
	private string _sessionId;
	private JSONValue _sessions;
	private SessionStorage _sessionStorage;

	this(SessionStorage sessionStorage)
	{
		this._sessionStorage = sessionStorage;
		this._sessionId = _sessionStorage.generateSessionId();
		this._sessions = parseJSON(_sessionStorage.get(_sessionId));
	}
	this(string sessionId,SessionStorage sessionStorage)
	{
		this._sessionId = sessionId;
		this._sessionStorage = sessionStorage;
		this._sessions = parseJSON(_sessionStorage.get(_sessionId));
	}
	Session set(string key,string value)
	{
		_sessions[key] = value;
		_sessionStorage.set(_sessionId,_sessions.toString);
		return this;
	}

	string get(string key)
	{
		try
		{
			return _sessions[key].str;
		}
		catch (Exception e)
		{
			return string.init;
		}
	}

	void remove(string key)
	{
		JSONValue json;
		
		foreach (string _key, ref value; _sessions)
        {
        	if (_key != key)
        	{
        		json[_key] = value;
        	}
        }

		_sessions = json;
		_sessionStorage.set(_sessionId, _sessions.toString);
	}

	string[] keys()
	{
		string[] ret;
		
		foreach (string key, value; _sessions)
        {
        	ret ~= key;
        }
        
        return ret;
	}

	string sessionId()
	{
		return _sessionId;
	}
}

class SessionStorage
{

	this(UCache cache)
	{
		_cache = cache;
	}


	alias set = put;

	bool put(string key, string value, int expire)
	{
		_cache.put!string(getRealAddr(key), value, expire);
		return true;
	}
	
	bool put(string key, string value)
	{
		return set(key,value,_expire);
	}
	
	string get(string key)
	{
		return  cast(string)_cache.get!string(getRealAddr(key));
	}
	
	alias isset = containsKey;
	bool containsKey(string key)
	{
		return _cache.containsKey(key);
	}
	
	alias del = erase;
	alias remove = erase;
	bool erase(string key)
	{
		return _cache.remove(getRealAddr(key));
	}


	string generateSessionId(string sessionName = "hunt_session")
	{
		import hunt.utils.random;
		SHA1 hash;
		hash.start();
		hash.put(getRandom);
		ubyte[20] result = hash.finish();
		string str = toLower(toHexString(result));

		JSONValue json;
		json[sessionName] = str;
		json["_time"] = getCurrUnixStramp + _expire; 

		set(str,json.toString,_expire);

		return str;
	}


	void setPrefix(string prefix)
	{
		_prefix = prefix;
	}

	void setExpire(int expire)
	{
		_expire = expire;
	}

	string getRealAddr(string key)
	{
		return _prefix ~ key;
	}

	int expire()
	{
		return _expire;
	}



	private
	{
		string 		_prefix;
		string 		_sessionId;

		int 		_expire;
		UCache 		_cache;
	}
}
