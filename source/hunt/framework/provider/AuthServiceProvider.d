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
            authService.addGuard(guard);
        } else if(icmp(guardScheme, cast(string)AuthenticationScheme.Bearer) == 0 || 
            icmp(guardScheme, "jwt") == 0) {
            JwtGuard guard = new JwtGuard();
            authService.addGuard(guard);
        } else {
            warningf("Unknown authentication scheme: %s. Use basic instead.", guardScheme);
            BasicGuard guard = new BasicGuard();
            authService.addGuard(guard);
        }

        authService.boot();
    }
}