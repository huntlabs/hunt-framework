module hunt.framework.auth.BasicAuthRealm;

import hunt.framework.auth.AuthRealm;
import hunt.framework.auth.Claim;
import hunt.framework.auth.ClaimTypes;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.JwtUtil;
import hunt.framework.auth.principal;
import hunt.framework.auth.UserDetails;
import hunt.framework.auth.UserService;
import hunt.framework.provider.ServiceProvider;

import hunt.collection.ArrayList;
import hunt.collection.Collection;
import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;
import hunt.shiro;
import hunt.String;

import std.format;


/**
 * 
 */
class BasicAuthRealm : AuthRealm {

    this(UserService userService) {
        super(userService);
    }

    override bool supports(AuthenticationToken token) {
        version(HUNT_AUTH_DEBUG) tracef("AuthenticationToken: %s", typeid(cast(Object)token));
        UsernamePasswordToken t = cast(UsernamePasswordToken)token;
        return t !is null;
    }

    // override protected UserService getUserService() {
    //     return _userService; //serviceContainer().resolve!UserService();
    // }

    override protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken token) {
        string username = token.getPrincipal();
        string password = cast(string)token.getCredentials();

        UserService userService = getUserService();
        version(HUNT_AUTH_DEBUG) {
            infof("username: %s, %s", username, typeid(cast(Object)userService));
        }        

        // To authenticate the user with username and password
        UserDetails user = userService.authenticate(username, password);
        
        if(user !is null) {

            version(HUNT_AUTH_DEBUG) infof("Realm: %s", getName());
            PrincipalCollection pCollection = new SimplePrincipalCollection(user, getName());
            String credentials = new String(password);
            SimpleAuthenticationInfo info = new SimpleAuthenticationInfo(pCollection, credentials);

            return info;
        } else {
            throw new IncorrectCredentialsException(username);
        }
    }
}