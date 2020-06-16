module hunt.framework.auth.UserAuthRealm;

import hunt.framework.auth.AuthRole;
import hunt.framework.auth.AuthUser;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.JwtUtil;
import hunt.framework.auth.UserService;
import hunt.framework.provider.ServiceProvider;

import hunt.logging.ConsoleLogger;
import hunt.shiro;
import hunt.String;


/**
 * 
 */
class UserAuthRealm : AuthorizingRealm {
    private UserService _userService;

    this() {
        _userService = serviceContainer().resolve!UserService();
    }

    override
    bool supports(AuthenticationToken token) {
        UsernamePasswordToken ut = cast(UsernamePasswordToken)token;
        return ut !is null;
    }

    override protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken token) {
        string username = token.getPrincipal();
        string password = cast(string)token.getCredentials();

        version(HUNT_DEBUG) {
            infof("principal: %s", username);
        }        

        // To authenticate the user with username and password
        AuthUser user = _userService.authenticate(username, password);
        
        if(user !is null) {
            String credentials = new String(password);
            SimpleAuthenticationInfo info = new SimpleAuthenticationInfo(user, credentials, getName());
            return info;
        } else {
            throw new IncorrectCredentialsException(username);
        }
    }

    override protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principals) {        
        AuthUser user = cast(AuthUser) principals.getPrimaryPrincipal();
        if(user is null) {
            warning("no principals");
            return null;
        }

        SimpleAuthorizationInfo info = new SimpleAuthorizationInfo();

        // To retrieve all the roles for the user from database
        AuthRole[] userRoles = user.roles;

        // Recording the permissions based on each role
        foreach(AuthRole r; userRoles) {
            // roles
            info.addRole(r.name);

            // permissions
            info.addStringPermissions(r.permissions);
        }

        return info;
    }
}