module hunt.http.session;

import huntlabs.cache;
import hunt.utils.time;
import hunt.exception;
import hunt.utils.random;

import std.ascii;
import std.json;
import std.conv;
import std.digest.sha;
import std.format;
import std.datetime;
import std.random;
import std.conv;

import core.cpuid;
import std.string;
import std.experimental.logger;

const SessionIdLenth = 20;

class Session
{
	private string _sessionId;
	private string[string] _sessions;
	private SessionStorage _sessionStorage;

	this(SessionStorage sessionStorage, bool canStart = true)
	{
		this._sessionStorage = sessionStorage;
		if (canStart)
		{
			this._sessionId = _sessionStorage.generateSessionId();
			this._sessions = to!(string[string]) (_sessionStorage.get(_sessionId));

			_isStarted = true;
		}
	}

	this(string sessionId, SessionStorage sessionStorage)
	{
		this._sessionId = sessionId;
		this._sessionStorage = sessionStorage;
		this._sessions = to!(string[string])(_sessionStorage.get(_sessionId));
	}

	Session set(string key, string value)
	{
		_sessions[key] = value;
		_sessionStorage.set(_sessionId, to!(string)(_sessions));
		return this;
	}

	void remove(string key)
	{
		string[string] json;

		foreach (string _key, ref string value; _sessions)
		{
			if (_key != key)
			{
				json[_key] = value;
			}
		}

		_sessions = json;
		_sessionStorage.set(_sessionId, to!(string)(_sessions));
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
		// trace("xxxx=>", s);
		if(!s.empty)
			this._sessions = to!(string[string])(s);
	}

	/**
     * Save the session data to storage.
     *
     * @return void
     */
	bool save()
	{
		_sessionStorage.set(_sessionId, to!(string)(_sessions));
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
		// throw new NotImplementedException("ageFlashData");
	}

	/**
     * Get all of the session data.
     *
     * @return array
     */
	string[string] all()
	{
		string[string] v;
		foreach (string key, string value; _sessions)
		{
			v[key] = value;
		}

		return v;
	}

	/**
     * Checks if a key exists.
     *
     * @param  string|array  $key
     * @return bool
     */
	bool exists(string key)
	{
		if (_sessions  is null)
			return false;
		string* item = key in _sessions;
		return item !is null;
	}

	/**
     * Checks if a key is present and not null.
     *
     * @param  string|array  $key
     * @return bool
     */
	bool has(string key)
	{
		if (_sessions  is null)
			return false;

		auto item = key in _sessions;
		if ((item !is null) && (!item.empty))
			return true;
		else
			return false;
	}

	/**
     * Get an item from the session.
     *
     * @param  string  $key
     * @param  mixed  $default
     * @return mixed
     */
	string get(string key)
	{
		if (_sessions is null)
			return null;

		auto item = key in _sessions;
		if (item is null)
			return null;
		else
			return *item;
		// try
		// {
		// 	return _sessions[key].str;
		// }
		// catch (Exception e)
		// {
		// 	return string.init;
		// }
	}

	/**
     * Get the value of a given key and then forget it.
     *
     * @param  string  $key
     * @param  string  $default
     * @return mixed
     */
	void pull(string key, string value)
	{
		_sessions[key] = value;
	}

	/**
     * Determine if the session contains old input.
     *
     * @param  string  $key
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
     * @param  string  $key
     * @param  mixed   $default
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
     * @param  array  $attributes
     * @return void
     */
	void replace(string[string] attributes)
	{
		put(attributes);
	}

	/**
     * Put a key / value pair or array of key / value pairs in the session.
     *
     * @param  string|array  $key
     * @param  mixed       $value
     * @return void
     */
	void put(string key, string value = null)
	{
		_sessions[key] = value;
	}

	/// ditto
	void put(string[string] pairs)
	{
		_sessions = pairs;

		// foreach (string key, string value; pairs)
		// 	_sessions[key] = value;
	}

	/**
     * Get an item from the session, or store the default value.
     *
     * @param  string  $key
     * @param  \Closure  $callback
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
     * @param  string  $key
     * @param  mixed   $value
     * @return void
     */
	void push(string key, string value)
	{
		this.put(key, value);
	}

	/**
     * Flash an input array to the session.
     *
     * @param  array  $value
     * @return void
     */
	void flashInput(string[string] value)
	{
		flash("_old_input", to!string(value));
	}

	void flush()
	{
		_sessions = null;
		_sessionStorage.clear();
	}

	/**
     * Flush the session data and regenerate the ID.
     *
     * @return bool
     */
	public bool invalidate()
	{
		flush();

		return migrate(true);
	}

	/**
     * Generate a new session ID for the session.
     *
     * @param  bool  $destroy
     * @return bool
     */
	public bool migrate(bool destroy = false)
	{
		if (destroy)
		{
			_sessionStorage.clear();
		}

		_sessionId = generateSessionId();

		return true;
	}

	/**
     * Flash a key / value pair to the session.
     *
     * @param  string  $key
     * @param  mixed   $value
     * @return void
     */
	void flash(string key, string value)
	{
		set(key, value);
	}

	/**
     * Determine if the session has been started.
     *
     * @return bool
     */
	public bool isStarted()
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
     * @param  string  $name
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
     * @param  string  $id
     * @return void
     */
	void setId(string id)
	{
		_sessionId = isValidId(id) ? id : generateSessionId();
	}

	/**
     * Determine if this is a valid session ID.
     *
     * @param  string  $id
     * @return bool
     */
	static bool isValidId(string id)
	{
		// if(id.length != SessionIdLenth)
		// 	return false;
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
	public string token()
	{
		return this.get("_token");
	}

	/**
     * Regenerate the CSRF token value.
     *
     * @return void
     */
	public void regenerateToken()
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
	public string previousUrl()
	{
		return this.get("_previous.url");
	}

	/**
     * Set the "previous" URL in the session.
     *
     * @param  string  $url
     * @return void
     */
	public void setPreviousUrl(string url)
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
