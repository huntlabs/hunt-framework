module hunt.framework.http.session.HttpSession;

import hunt.datetime;
import hunt.util.exception;
import hunt.framework.utils.random;

import std.datetime;
import std.digest.sha;
import std.json;
import std.string;
import std.traits;


__gshared string DefaultSessionIdName = "hunt_session";

/**
 * 
 */
class HttpSession  {

    private string id;
    private long creationTime;
    private long lastAccessedTime;
    private int maxInactiveInterval;
    private JSONValue attributes;
    private bool newSession;

    string getId() {
        return id;
    }

    void setId(string id) {
        this.id = id;
    }

    long getCreationTime() {
        return creationTime;
    }

    void setCreationTime(long creationTime) {
        this.creationTime = creationTime;
    }

    long getLastAccessedTime() {
        return lastAccessedTime;
    }

    void setLastAccessedTime(long lastAccessedTime) {
        this.lastAccessedTime = lastAccessedTime;
    }

    /**
     * Get the max inactive interval. The time unit is second.
     *
     * @return The max inactive interval.
     */
    int getMaxInactiveInterval() {
        return maxInactiveInterval;
    }

    /**
     * Set the max inactive interval. The time unit is second.
     *
     * @param maxInactiveInterval The max inactive interval.
     */
    void setMaxInactiveInterval(int maxInactiveInterval) {
        this.maxInactiveInterval = maxInactiveInterval;
    }

    ref JSONValue getAttributes() {
        return attributes;
    }

    void setAttributes(ref JSONValue attributes) {
        this.attributes = attributes;
    }

    bool isNewSession() {
        return newSession;
    }

    void setNewSession(bool newSession) {
        this.newSession = newSession;
    }

    bool isValid() {
        long currentTime = convert!(TimeUnits.HectoNanosecond, TimeUnits.Millisecond)(Clock.currStdTime);
        return (currentTime - lastAccessedTime) < (maxInactiveInterval * 1000);
    }

    void set(T)(string name, T value) {
        this.attributes[name] = JSONValue(value);
    }

    T get(T=string)(string name, T defaultValue = T.init) {
        const(JSONValue)* itemPtr = name in attributes;
        if(itemPtr is null)
            return defaultValue;
        static if(isStaticArray!T && is(T foo : U[], U)) {
            U[] r;
            foreach(JSONValue jv; itemPtr.array)  {
                r ~= get!U(jv);
            }
            return r;
        } else {
            return get!T(*itemPtr);
        }
    }

    private static T get(T=string)(JSONValue itemPtr) {
        static if(is(T == string))
            return itemPtr.str;
        else static if(isIntegral!T) {
            return cast(T)itemPtr.integer;
        } else static if(isFloatingPoint!T) {
            return cast(T)itemPtr.floating;
        } else {
            static assert(false, "Unsupported type: " ~ typeid(T).name);
        }
    }

    override bool opEquals(Object o) {
        if (this is o) return true;
        HttpSession that = cast(HttpSession) o;
        if(that is null) return false;
        return id == that.id;
    }

    override size_t toHash() @trusted nothrow {
        return hashOf(id);
    }

    static HttpSession create(string id, int maxInactiveInterval) {
        long currentTime = convert!(TimeUnits.HectoNanosecond, TimeUnits.Millisecond)(Clock.currStdTime);
        HttpSession session = new HttpSession();
        session.setId(id);
        session.setMaxInactiveInterval(maxInactiveInterval);
        session.setCreationTime(currentTime);
        session.setLastAccessedTime(session.getCreationTime());
        // session.setAttributes(new HashMap!(string, Object)());
        session.setNewSession(true);
        return session;
    }

    static string toJson(HttpSession session) {
        JSONValue j;
        j["CreationTime"] = session.creationTime;
        j["attr"] = session.attributes;
        return j.toString();
    }

    static HttpSession fromJson(string id, string json) {
        JSONValue j = parseJSON(json);
        long currentTime = convert!(TimeUnits.HectoNanosecond, TimeUnits.Millisecond)(Clock.currStdTime);
        HttpSession session = new HttpSession();
        session.setId(id);
        session.setCreationTime(j["CreationTime"].integer);
        session.setLastAccessedTime(currentTime);
        session.setNewSession(false);
        session.attributes = j["attr"];

        return session;
    }

	static string generateSessionId(string sessionName = DefaultSessionIdName) {
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
}




/**
 * 
 */
class SessionInvalidException : RuntimeException {
    this() {
        super("");
    }

    this(string msg) {
        super(msg);
    }
}

/**
 * 
 */
class SessionNotFound : RuntimeException {
    this() {
        super("");
    }

    this(string msg) {
        super(msg);
    }
}
