module hunt.framework.auth.guard.Guard;

import hunt.framework.auth.AuthOptions;
import hunt.framework.auth.AuthRealm;
import hunt.framework.auth.HuntShiroCache;
import hunt.framework.auth.ShiroCacheManager;
import hunt.framework.auth.UserService;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.http.Request;
import hunt.framework.provider.ServiceProvider;
import hunt.http.AuthenticationScheme;
import hunt.shiro;
import hunt.shiro.session.mgt.SessionManager;
import hunt.shiro.session.mgt.DefaultSessionManager;

import hunt.logging.Logger;



/**
 * 
 */
abstract class Guard {
    private DefaultSecurityManager _securityManager;
    private Realm[] _realms;
    private UserService _userService;
    private int _tokenExpiration = DEFAULT_TOKEN_EXPIRATION*24*60*60;
    private AuthenticationScheme _authScheme = AuthenticationScheme.Bearer;
    private string _tokenCookieName = JWT_COOKIE_NAME;

    private string _name;

    this(UserService userService, string name = DEFAULT_GURAD_NAME) {
        _userService = userService;
        _name = name;

        ApplicationConfig appConfig = serviceContainer().resolve!ApplicationConfig();
        _tokenExpiration = appConfig.auth.tokenExpiration;
    }

    string name() {
        return _name;
    }

    UserService userService() {
        return _userService;
    }

    Guard tokenExpiration(int value) {
        _tokenExpiration = value;
        return this;
    }

    int tokenExpiration() {
        return _tokenExpiration;
    }

    Guard tokenCookieName(string value) {
        _tokenCookieName = value;
        return this;
    }

    string tokenCookieName() {
        return _tokenCookieName;
    }

    AuthenticationScheme authScheme() {
        return _authScheme;
    }

    Guard authScheme(AuthenticationScheme value) {
        _authScheme = value;
        return this;
    }

    Guard addRealms(AuthRealm realm) {
        _realms ~= cast(Realm)realm;
        return this;
    }

    AuthenticationToken getToken(Request request);

    void boot() {
        HuntCache cache = serviceContainer().resolve!HuntCache();
        CacheManager cacheManager = new ShiroCacheManager(cache);        
        _securityManager = new DefaultSecurityManager();
        DefaultSessionManager sm = cast(DefaultSessionManager)_securityManager.getSessionManager();

        if(sm !is null) {
            sm.setGlobalSessionTimeout(_tokenExpiration*1000);
        }

        SecurityUtils.setSecurityManager(_name, _securityManager);
        _securityManager.setRealms(_realms);
        _securityManager.setCacheManager(cacheManager);        
    }

}