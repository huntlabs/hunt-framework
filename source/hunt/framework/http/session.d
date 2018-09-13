module hunt.framework.http.session;

import hunt.cache;
import hunt.framework.exception;
import hunt.framework.utils.random;

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
import hunt.util.exception;

const SessionIdLenth = 20;


/**
*/
class Session
{
	private string _sessionId;
	private JSONValue _sessions;
	private SessionStorage _sessionStorage;

	this(SessionStorage sessionStorage, bool canStart = true)
	{
		this._sessionStorage = sessionStorage;
		if (canStart)
		{
			this._sessionId = _sessionStorage.generateSessionId();
			this._sessions = parseJSON(_sessionStorage.get(_sessionId));

			_isStarted = true;
		}
	}

	this(string sessionId, SessionStorage sessionStorage)
	{
		this._sessionId = sessionId;
		this._sessionStorage = sessionStorage;
		this._sessions = parseJSON(_sessionStorage.get(_sessionId));
	}

	Session set(string key, string value)
	{
		_sessions[key] = value;
		_sessionStorage.set(_sessionId, _sessions.toString);
		return this;
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

	/**
     * Start the session, reading the data from a handler.
     *
     * @return bool
     */
	bool start()
	{
		if (_sessionId.empty)
			_sessionId = generateSessionId();
		else
		{
			loadSession();

			if (!this.has("_token"))
				this.regenerateToken();
		}
		_isStarted = true;
		return _isStarted;
	}

	/**
     * Load the session data from the handler.
     *
     * @return void
     */
	protected void loadSession()
	{
		string s = _sessionStorage.get(_sessionId);
		if (!s.empty)
			this._sessions = parseJSON(s);
	}

	/**
     * Save the session data to storage.
     *
     * @return void
     */
	bool save()
	{
		_sessionStorage.set(_sessionId, _sessions.toString);
		_isStarted = false;
		return _isStarted;
	}

	/**
     * Age the flash data for the session.
     *
     * @return void
     */
	void ageFlashData()
	{
		implementationMissing(false);
	}

	/**
     * Get all of the session data.
     *
     * @return array
     */
	string[string] all()
	{
		if(_sessions.isNull)
			return null;

		string[string] v;
		foreach (string key, ref JSONValue value; _sessions)
		{
			if(value.type == JSON_TYPE.STRING)
				v[key] = value.str;
			else
				v[key] = value.toString();
		}

		return v;
	}

	/**
     * Checks if a key exists.
     *
     * @param  string|array  key
     * @return bool
     */
	bool exists(string key)
	{
		if (_sessions.isNull)
			return false;
		const(JSONValue)* item = key in _sessions;
		return item !is null;
	}

	/**
     * Checks if a key is present and not null.
     *
     * @param  string|array  key
     * @return bool
     */
	bool has(string key)
	{
		if (_sessions.isNull)
			return false;

		auto item = key in _sessions;
		if ((item !is null) && (!item.str.empty))
			return true;
		else
			return false;
	}

	/**
     * Get an item from the session.
     *
     * @param  string  key
     * @param  mixed  default
     * @return mixed
     */
	T get(T = string)(string key)
	{
		if (_sessions.isNull)
			return T.init;

		auto item = key in _sessions;
		if (item is null)
			return T.init;

		static if (is(T : string))
			return item.str;
		else static if (is(T: U[], U))
		{
			U[] r;
			foreach(ref const(JSONValue) v; item.array)
			{
				static if(is(U:string))
				{
					r ~= v.str;
				}
				else static if(isNumeric(U))
				{
					r ~= cast(U) v.integer;
				}
				else
				 static assert(false, "unsupported type: " ~ U.stringof);
			}
			return r;
		}
		else
			item.toString();
	}

	/**
     * Get the value of a given key and then forget it.
     *
     * @param  string  key
     * @param  string  default
     * @return mixed
     */
	void pull(string key, string value)
	{
		_sessions[key] = value;
	}

	/**
     * Determine if the session contains old input.
     *
     * @param  string  key
     * @return bool
     */
	bool hasOldInput(string key)
	{
		string old = getOldInput(key);
		return !old.empty;
	}

	/**
     * Get the requested item from the flashed input array.
     *
     * @param  string  key
     * @param  mixed   default
     * @return mixed
     */
	string[string] getOldInput(string[string] defaults = null)
	{
		string v = get("_old_input");
		if (v.empty)
			return defaults;
		else
			return to!(string[string])(v);
	}

	/// ditto
	string getOldInput(string key, string defaults = null)
	{
		string old = get("_old_input");
		string[string] v = to!(string[string])(old);
		return v.get(key, defaults);
	}

	/**
     * Replace the given session attributes entirely.
     *
     * @param  array  attributes
     * @return void
     */
	void replace(string[string] attributes)
	{
		_sessions = JSONValue.init;
		put(attributes);
	}

	/**
     * Put a key / value pair or array of key / value pairs in the session.
     *
     * @param  string|array  key
     * @param  mixed       value
     * @return void
     */
	void put(T=string)(string key, T value)
	{
		_sessions[key] = value;
	}

	/// ditto
	void put(string[string] pairs)
	{
		foreach (string key, string value; pairs)
			_sessions[key] = value;
	}


	/**
     * Get an item from the session, or store the default value.
     *
     * @param  string  key
     * @param  \Closure  callback
     * @return mixed
     */
	string remember(string key, string value)
	{
		string v = this.get(key);
		if (!v.empty)
			return v;

		this.put(key, value);
		return value;
	}

	/**
     * Push a value onto a session array.
     *
     * @param  string  key
     * @param  mixed   value
     * @return void
     */
	void push(T=string)(string key, T value)
	{
		T[] array = this.get!(T[])(key);
		array ~= value;

		this.put(key, array);
	}

	/**
     * Flash a key / value pair to the session.
     *
     * @param  string  key
     * @param  mixed   value
     * @return void
     */
	void flash(T = string)(string key, T value)
	{
		this.put(key, value);
		this.push("_flash.new", key);
		this.removeFromOldFlashData([key]);
	}

    /**
     * Flash a key / value pair to the session for immediate use.
     *
     * @param  string key
     * @param  mixed value
     * @return void
     */
    void now(T = string)(string key, T value)
    {
        this.put(key, value);
        this.push("_flash.old", key);
    }

    /**
     * Reflash all of the session flash data.
     *
     * @return void
     */
    public void reflash()
    {
        this.mergeNewFlashes(this.get!(string[])("_flash.old"));
        this.put!(string[])("_flash.old", []);
    }

    /**
     * Reflash a subset of the current flash data.
     *
     * @param  array|mixed  keys
     * @return void
     */
	 void keep(string[] keys...)
	 {
		 mergeNewFlashes(keys);
		 removeFromOldFlashData(keys);
	 }

	/**
     * Merge new flash keys into the new flash array.
     *
     * @param  array  keys
     * @return void
     */
    protected void mergeNewFlashes(string[] keys)
    {
		string[] oldKeys = this.get!(string[])("_flash.new");
        string[] values = oldKeys ~ keys;
		values = values.sort().uniq().array;

        this.put("_flash.new", values);
    }

	/**
     * Remove the given keys from the old flash data.
     *
     * @param  array  keys
     * @return void
     */
	protected void removeFromOldFlashData(string[] keys)
	{
		string[] olds = this.get!(string[])("_flash.old");
		string[] news = olds.remove!(x => keys.canFind(x));
		this.put("_flash.old", news);
	}

	/**
     * Flash an input array to the session.
     *
     * @param  array  value
     * @return void
     */
	void flashInput(string[string] value)
	{
		flash("_old_input", to!string(value));
	}

    /**
     * Remove an item from the session, returning its value.
     *
     * @param  string  key
     * @return mixed
     */
	//string remove(string key)
	//{
	//	 string r = _sessions[key].toString();
	//	 _sessions[key] = JSONValue.init;
	//	 return r;
	//}

    /**
     * Remove one or many items from the session.
     *
     * @param  string|array  keys
     * @return void
     */
    void forget(string[] keys)
    {
		foreach(string k; keys)
		{
			_sessions[k] = JSONValue.init;
			// _sessions.remove(k);
		}
    }

    /**
     * Remove all of the items from the session.
     *
     * @return void
     */
	void flush()
	{
		_sessions = JSONValue.init;
		_sessionStorage.clear();
	}

	/**
     * Flush the session data and regenerate the ID.
     *
     * @return bool
     */
	bool invalidate()
	{
		flush();

		return migrate(true);
	}

    /**
     * Generate a new session identifier.
     *
     * @param  bool  destroy
     * @return bool
     */
    // public bool regenerate(bool destroy = false)
    // {
	// 	implementationMissing(false);
    // }

	/**
     * Generate a new session ID for the session.
     *
     * @param  bool  destroy
     * @return bool
     */
	bool migrate(bool destroy = false)
	{
		if (destroy)
		{
			_sessionStorage.clear();
		}

		_sessionId = generateSessionId();

		return true;
	}

	/**
     * Determine if the session has been started.
     *
     * @return bool
     */
	bool isStarted()
	{
		return _isStarted;
	}

	private bool _isStarted = false;

	/**
     * Get the name of the session.
     *
     * @return string
     */
	string getName()
	{
		return _name;
	}

	private string _name = "hunt_session";

	/**
     * Set the name of the session.
     *
     * @param  string  name
     * @return void
     */
	void setName(string name)
	{
		_name = name;
	}

	/**
     * Get the current session ID.
     *
     * @return string
     */
	string getId()
	{
		return _sessionId;
	}

	/**
     * Set the session ID.
     *
     * @param  string  id
     * @return void
     */
	void setId(string id)
	{
		_sessionId = isValidId(id) ? id : generateSessionId();
	}

	/**
     * Determine if this is a valid session ID.
     *
     * @param  string  id
     * @return bool
     */
	static bool isValidId(string id)
	{
		if(id.length != SessionIdLenth*2)
			return false;
		foreach (char c; id)
		{
			if (!isAlphaNum(c))
				return false;
		}
		return true;
	}

	/**
     * Get the CSRF token value.
     *
     * @return string
     */
	string token()
	{
		return this.get("_token");
	}

	/**
     * Regenerate the CSRF token value.
     *
     * @return void
     */
	void regenerateToken()
	{
		ubyte[] result = getRandom(SessionIdLenth);
		string str = toLower(toHexString(result));

		this.put("_token", str);
	}

	/**
     * Get the previous URL from the session.
     *
     * @return string|null
     */
	string previousUrl()
	{
		return this.get("_previous.url");
	}

	/**
     * Set the "previous" URL in the session.
     *
     * @param  string  url
     * @return void
     */
	void setPreviousUrl(string url)
	{
		this.put("_previous.url", url);
	}

	/**
     * Get a new, random session ID.
     *
     * @return string
     */
	string generateSessionId()
	{
		SHA1 hash;
		hash.start();
		hash.put(getRandom);
		ubyte[SessionIdLenth] result = hash.finish();
		string str = toLower(toHexString(result));

		return str;
	}

}

int getCurrUnixStramp()
{
	return cast(int)(Clock.currTime.toUnixTime);
}

/**
*/
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
		return set(key, value, _expire);
	}

	string get(string key)
	{
		return cast(string) _cache.get!string(getRealAddr(key));
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
		SHA1 hash;
		hash.start();
		hash.put(getRandom);
		ubyte[20] result = hash.finish();
		string str = toLower(toHexString(result));

		JSONValue json;
		json[sessionName] = str;
		json["_time"] = getCurrUnixStramp + _expire;

		set(str, json.toString, _expire);

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

	void clear()
	{
		_cache.clear();
	}

	private
	{
		string _prefix;
		string _sessionId;

		int _expire;
		UCache _cache;
	}
}

Session session()
{
	import hunt.framework.http.request;

	return request().session();
}

string session(string key)
{
	return session().get(key);
}

void session(string[string] values)
{
	import hunt.framework.http.request;
	
	foreach (key, value; values)
	{
		session().put(key, value);
	}
}
