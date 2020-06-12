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
        serviceContainer().register!(AuthorizingRealm, UserAuthRealm).newInstance;
        serviceContainer().register!(AuthorizingRealm, JwtAuthRealm).newInstance;
    }

    override void boot() {
        HuntCache cache = serviceContainer().resolve!HuntCache();
        AuthorizingRealm[] realms = serviceContainer().resolveAll!(AuthorizingRealm)();

        DefaultSecurityManager securityManager = new DefaultSecurityManager();
        securityManager.setRealms(realms);
        
        CacheManager cacheManager = new ShiroCacheManager(cache);
        securityManager.setCacheManager(cacheManager);

        SecurityUtils.setSecurityManager(securityManager);
    }
}