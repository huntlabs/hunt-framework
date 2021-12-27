module hunt.framework.auth.ShiroCacheManager;

import hunt.framework.auth.HuntShiroCache;

import hunt.shiro.cache.AbstractCacheManager;
import hunt.shiro.authz.AuthorizationInfo;
import hunt.cache.Cache;
import hunt.shiro.cache.Cache;

import hunt.logging;


/**
 * 
 */
class ShiroCacheManager : AbstractCacheManager!(Object, AuthorizationInfo) {

    private HuntCache _cache;

    this(HuntCache cache){
        _cache = cache;
    }

    override protected HuntShiroCache createCache(string name) {
        return new HuntShiroCache(name, _cache);
    }
}