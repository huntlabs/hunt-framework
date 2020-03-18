module hunt.framework.auth.HuntShiroCache;

import hunt.redis;
import hunt.cache.Cache;
import hunt.shiro;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.serialization.JsonSerializer;

import std.array;
import std.conv;
import std.json;

alias ShiroCache = hunt.shiro.cache.Cache.Cache;
alias HuntCache = hunt.cache.Cache.Cache;



/**
 * 
 */
class HuntShiroCache : ShiroCache!(Object, AuthorizationInfo) {
    /**
     * The name of this cache.
     */
    private string _name;
    private HuntCache _cache;

    this(string name, HuntCache cache) {
        _name = name;
        _cache = cache;
    }

    AuthorizationInfo get(Object key) {
        version(HUNT_DEBUG) tracef("%s, hash: %d", key.toString, key.toHash());
        string k = key.toHash().to!string(); // key.toString();
        if(!_cache.hasKey(k)) {
            return null;
        }
        SimpleAuthorizationInfo obj = new SimpleAuthorizationInfo();

        string v = _cache.get(k);
        if(v.empty) {
            warningf("value is empty for key: ", k);
            return obj;
        }

        // version(HUNT_DEBUG) tracef("key: %s, value: %s", k, v);
        JSONValue jv = parseJSON(v);
        
        string[] roles = JsonSerializer.toObject!(string[])(jv["roles"]);
        string[] permissions = JsonSerializer.toObject!(string[])(jv["permissions"]);

        obj.addRoles(roles);
        obj.addStringPermissions(permissions);

        return obj;
    }
    
    AuthorizationInfo get(Object key, AuthorizationInfo defaultValue) {
        AuthorizationInfo authInfo = get(key);
        if(authInfo is null)
            return defaultValue;
        return authInfo;
    }

    AuthorizationInfo put(Object key, AuthorizationInfo value) {
        version(HUNT_DEBUG) tracef("%s, hash: %d", key.toString, key.toHash());
        string k = key.toHash().to!string(); // key.toString();

        string[] roles = value.getRoles().toArray();
        string[] permissions = value.getStringPermissions().toArray();

        JSONValue jv;
        jv["roles"] = roles;
        jv["permissions"] = permissions;

        string v = jv.toString();
        version(HUNT_HTTP_DEBUG) info(v);

        _cache.set(k, v);
        return value;
    }

    AuthorizationInfo remove(Object key) {
        warningf("%s, %d", key.toString, key.toHash());
        string k = key.toHash().to!string(); // key.toString();
        if(!_cache.hasKey(k)) {
            return null;
        }

        // AuthorizationInfo value = _cache.get(k);
        _cache.remove(k);
        implementationMissing(false);
        return null;
    }

    void clear() {
        _cache.clear();
    }

    int size() {
        implementationMissing(false);
        return 0;
    }

    Object[] keys() {
        implementationMissing(false);
        return null;
    }

    AuthorizationInfo[] values() {
        implementationMissing(false);
        return null;
    }
}
