module hunt.framework.auth.HuntShiroCache;

import hunt.redis;
import hunt.cache.Cache;
import hunt.shiro;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.serialization.JsonSerializer;

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
        warning("xxx=>", key.toString);
        string k = key.toString();
        if(!_cache.hasKey(k)) {
            return null;
        }

        string v = _cache.get(k);
        trace("key: %s, value: %s", k, v);
        // AuthorizationInfo obj = JsonSerializer.toObject!(SimpleAuthorizationInfo)(v);
        JSONValue jv = parseJSON(v);
        
        string[] roles = JsonSerializer.toObject!(string[])(jv["roles"]);
        string[] permissions = JsonSerializer.toObject!(string[])(jv["permissions"]);
        
        trace(roles);
        trace(permissions);

        SimpleAuthorizationInfo obj = new SimpleAuthorizationInfo();
        obj.addRoles(roles);
        implementationMissing(false);
        // obj.addStringPermission(permissions);

        return obj;
    }
    
    AuthorizationInfo get(Object key, AuthorizationInfo defaultValue) {
        // return map.get(key, defaultValue);
        AuthorizationInfo authInfo = get(key);
        if(authInfo is null)
            return defaultValue;
        return authInfo;
    }

    AuthorizationInfo put(Object key, AuthorizationInfo value) {
        warning("xxx=>", key.toString);
        SimpleAuthorizationInfo authInfo = cast(SimpleAuthorizationInfo)value;
        if(authInfo !is null) {
            string v = JsonSerializer.toJson(authInfo).toString();
            trace(v);
        } else {
            warning("It's not a SimpleAuthorizationInfo.");
        }

        string[] roles = value.getRoles().toArray();
        string[] permissions = value.getStringPermissions().toArray();

        JSONValue jv;
        jv["roles"] = roles;
        jv["permissions"] = permissions;
        info(jv.toString());

        _cache.set(key.toString, jv);
        return value;
    }

    AuthorizationInfo remove(Object key) {
        warning("xxx=>", key.toString);
        string k = key.toString();
        if(!_cache.hasKey(k)) {
            return null;
        }

        // AuthorizationInfo value = _cache.get(k);
        _cache.remove(k);
        // return value;
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
