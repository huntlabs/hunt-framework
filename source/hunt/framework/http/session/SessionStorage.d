module hunt.framework.http.session.SessionStorage;

import hunt.cache;
import hunt.framework.Exceptions;
import hunt.framework.util.Random;

import std.array;
import std.algorithm;
import std.ascii;
import std.json;
import std.conv;
import std.digest.sha;
import std.format;
import std.datetime;
import std.random;
import std.conv;
import std.traits;

import core.cpuid;
import std.string;
import hunt.Exceptions;

import hunt.framework.http.session.HttpSession;

/**
*/
class SessionStorage {
	this(Cache cache) {
		_cache = cache;
	}

	alias set = put;

	bool put(HttpSession session) {
		int expire = session.getMaxInactiveInterval;
		if(_expire < expire)
			expire = _expire;
		string key = session.getId();
		_cache.set(getRealAddr(key), HttpSession.toJson(session), _expire);
		return true;
	}

	HttpSession get(string key) {
		string keyWithPrefix = getRealAddr(key);
		string s = cast(string) _cache.get!string(keyWithPrefix);
		if(s.empty) {
			// string sessionId = HttpSession.generateSessionId();
			// return HttpSession.create(sessionId, _sessionStorage.expire);
			return null;
		} else {
			_cache.set(keyWithPrefix , s , _expire);
			return HttpSession.fromJson(key, s);
		}
	}

	// string _get(string key) {
	// 	return cast(string) _cache.get!string(getRealAddr(key));
	// }

	// alias isset = containsKey;
	bool containsKey(string key) {
		return _cache.hasKey(getRealAddr(key));
	}

	// alias del = erase;
	// alias remove = erase;
	bool remove(string key) {
		return _cache.remove(getRealAddr(key));
	}

	static string generateSessionId(string sessionName = "hunt_session") {
		SHA1 hash;
		hash.start();
		hash.put(getRandom);
		ubyte[20] result = hash.finish();
		string str = toLower(toHexString(result));

		// JSONValue json;
		// json[sessionName] = str;
		// json["_time"] = cast(int)(Clock.currTime.toUnixTime) + _expire;

		// put(str, json.toString, _expire);

		return str;
	}

	void setPrefix(string prefix) {
		_prefix = prefix;
	}

	void expire(int expire) @property {
		_expire = expire;
	}

	int expire() @property {
		return _expire;
	}

	string getRealAddr(string key) {
		return _prefix ~ key;
	}

	void clear() {
		_cache.clear();
	}

	private {
		string _prefix;
		string _sessionId;

		int _expire;
		Cache _cache;
	}
}
