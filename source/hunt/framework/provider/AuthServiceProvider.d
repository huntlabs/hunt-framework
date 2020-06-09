module hunt.framework.provider.AuthServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.auth;
import hunt.logging.ConsoleLogger;
import hunt.shiro;

import poodinis;

/**
 * 
 */
class AuthServiceProvider : ServiceProvider {

    override void register() {
        serviceContainer().register!(AuthorizingRealm, IniRealm).newInstance;
    }

    override void boot() {
        HuntCache cache = serviceContainer().resolve!HuntCache();
        AuthorizingRealm realm = serviceContainer().resolve!(AuthorizingRealm)();

        DefaultSecurityManager securityManager = new DefaultSecurityManager();
        securityManager.setRealm(realm);
        
        CacheManager cacheManager = new ShiroCacheManager(cache);
        securityManager.setCacheManager(cacheManager);

        SecurityUtils.setSecurityManager(securityManager);
    }
}