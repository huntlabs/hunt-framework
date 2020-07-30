module hunt.framework.auth.Guard;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.auth;
import hunt.shiro;

import hunt.logging.ConsoleLogger;

/**
 * 
 */
class Guard {
    private DefaultSecurityManager _securityManager;
    private Realm[] _realms;
    private UserService _userService;

    private string _name;

    this(UserService userService, string name = DEFAULT_GURAD_NAME) {
        _userService = userService;
        _name = name;

        initializeRealms();
    }

    protected void initializeRealms() {
        _realms ~= cast(Realm) new BasicAuthRealm(_userService);
        _realms ~= cast(Realm) new JwtAuthRealm(_userService);
    }

    string name() {
        return _name;
    }

    void addRealms(AuthRealm realm) {
        _realms ~= cast(Realm)realm;
    }

    void boot() {
        HuntCache cache = serviceContainer().resolve!HuntCache();
        CacheManager cacheManager = new ShiroCacheManager(cache);        
        _securityManager = new DefaultSecurityManager();

        SecurityUtils.setSecurityManager(_name, _securityManager);
        _securityManager.setRealms(_realms);
        _securityManager.setCacheManager(cacheManager);        
    }

}