module hunt.framework.auth.JwtAuthRealm;

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
class JwtAuthRealm : AuthorizingRealm {
    private UserService _userService;

    this() {
        _userService = serviceContainer().resolve!UserService();
    }

    override
    bool supports(AuthenticationToken token) {
        JwtToken jt = cast(JwtToken)token;
        return jt !is null;
    }

    override protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken token) {
        string tokenString = token.getPrincipal();
        string username = JwtUtil.getUsername(tokenString);

        version(HUNT_DEBUG) {
            infof("tokenString: %s,  principal: %s", tokenString, username);
        }        

        // To retrieve the user info from username
        AuthUser user = _userService.getByName(username);

        // Valid the user using JWT
        if(JwtUtil.verify(tokenString, username, user.password)) {
                String credentials = new String(tokenString);
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