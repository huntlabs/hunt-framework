module hunt.framework.provider.AuthServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config;
import hunt.framework.auth;
import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;
import hunt.shiro;

import std.algorithm;
import std.array;
import std.string;
import poodinis;

/**
 * 
 */
class AuthServiceProvider : ServiceProvider {

    override void register() {
        container().register!(AuthService);
    }

    override void boot() {
        AuthService authService = container().resolve!AuthService();
        ApplicationConfig appConfig = container().resolve!ApplicationConfig();

        string guardScheme = appConfig.auth.guardScheme;
        if(icmp(guardScheme, cast(string)AuthenticationScheme.Basic) == 0) {
            BasicGuard guard = new BasicGuard();
            // guard.tokenExpiration = appConfig.auth.tokenExpiration;
            // guard.authScheme = AuthenticationScheme.Basic;
            // guard.tokenCookieName = BASIC_COOKIE_NAME;
            authService.addGuard(guard);
        } else if(icmp(guardScheme, cast(string)AuthenticationScheme.Bearer) == 0 || 
            icmp(guardScheme, "jwt") == 0) {
            JwtGuard guard = new JwtGuard();
            // guard.authScheme = AuthenticationScheme.Bearer;
            // guard.tokenCookieName = JWT_COOKIE_NAME;
            authService.addGuard(guard);
        } else {
            warningf("Unknown authentication scheme: %s", guardScheme);
        }

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