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
        serviceContainer().register!(AuthService);
    }

    override void boot() {
        AuthService authService = serviceContainer().resolve!AuthService();
        authService.addGuard(new Guard(new SimpleUserService(), DEFAULT_GURAD_NAME));
        authService.boot();
    }

    // private Realm[][string] _groupedRealms;

    // override void register() {
    //     // serviceContainer().register!(AuthorizingRealm, IniRealm).newInstance;
    //     serviceContainer().register!(AuthorizingRealm, BasicAuthRealm).newInstance;
    //     serviceContainer().register!(AuthorizingRealm, JwtAuthRealm).newInstance;
    // }

    // override void boot() {
    //     HuntCache cache = serviceContainer().resolve!HuntCache();
    //     CacheManager cacheManager = new ShiroCacheManager(cache);

    //     AuthorizingRealm[] authorizingRealms = serviceContainer().resolveAll!(AuthorizingRealm)(ResolveOption.noResolveException);
    //     foreach(AuthorizingRealm realm; authorizingRealms) {
    //         AuthRealm authRealm = cast(AuthRealm)realm;

    //         if(authRealm is null) continue;
    //         string guardName = authRealm.guardName();
    //         _groupedRealms[guardName] ~= cast(Realm)authRealm;
    //     }
    //     // Realm[] realms = authorizingRealms.map!(a => cast(Realm)a).array;

    //     foreach(string guardName, Realm[] realms; _groupedRealms) {
    //         DefaultSecurityManager securityManager = cast(DefaultSecurityManager) SecurityUtils.getSecurityManager(guardName);
    //         if(securityManager is null) {
    //             securityManager = new DefaultSecurityManager();
    //             SecurityUtils.setSecurityManager(guardName, securityManager);
    //             securityManager.setRealms(realms);
    //             securityManager.setCacheManager(cacheManager);
    //         }            
    //     }

    // }
}