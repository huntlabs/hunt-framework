module hunt.framework.provider.AuthServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.auth;
import hunt.logging.ConsoleLogger;
import hunt.shiro;

import std.algorithm;
import std.array;
import poodinis;

/**
 * 
 */
class AuthServiceProvider : ServiceProvider {

    override void register() {
        // serviceContainer().register!(AuthorizingRealm, IniRealm).newInstance;
        serviceContainer().register!(AuthorizingRealm, BasicAuthRealm).newInstance;
        serviceContainer().register!(AuthorizingRealm, JwtAuthRealm).newInstance;
        // serviceContainer().register!(UserService, DefaultUserService).singleInstance;
    }

    override void boot() {
        HuntCache cache = serviceContainer().resolve!HuntCache();
        AuthorizingRealm[] authorizingRealms = serviceContainer().resolveAll!(AuthorizingRealm)();
        Realm[] realms = authorizingRealms.map!(a => cast(Realm)a).array;

        DefaultSecurityManager securityManager = new DefaultSecurityManager();
        securityManager.setRealms(realms);
        
        CacheManager cacheManager = new ShiroCacheManager(cache);
        securityManager.setCacheManager(cacheManager);

        SecurityUtils.setSecurityManager(securityManager);
    }
}