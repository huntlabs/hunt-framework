module hunt.framework.auth.JwtAuthRealm;

import hunt.framework.auth.Identity;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.JwtUtil;
import hunt.framework.auth.UserDetails;
import hunt.framework.auth.UserService;
import hunt.framework.provider.ServiceProvider;

import hunt.logging.ConsoleLogger;
import hunt.shiro;
import hunt.String;

import std.range;


/**
 * See_also:
 *  [Springboot Integrate with Apache Shiro](http://www.andrew-programming.com/2019/01/23/springboot-integrate-with-jwt-and-apache-shiro/)
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
        if (username.empty) {
            throw new AuthenticationException("token invalid");
        }

        version(HUNT_DEBUG) {
            infof("tokenString: %s,  principal: %s", tokenString, username);
        }        

        // To retrieve the user info from username
        UserDetails user = _userService.getByName(username);
        if(user is null) {
            throw new AuthenticationException("User didn't existed!");
        }

        // Valid the user using JWT
        if(!JwtUtil.verify(tokenString, username, user.password)) {
            throw new IncorrectCredentialsException("Username or password error: " ~ username);
        }

        String principal = new String(username);
        String credentials = new String(tokenString);
        SimpleAuthenticationInfo info = new SimpleAuthenticationInfo(principal, credentials, getName());
        return info;
    }

    override protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principals) {
        String principal = cast(String) principals.getPrimaryPrincipal();
        if(principal is null) {
            warning("No principal avaliable");
            return null;
        }

        string username = principal.value();
        
        // To retrieve all the roles and permissions for the user from database
        UserDetails user = _userService.getByName(username);
        if(user is null) {
            throw new AuthenticationException("User didn't existed!");
        }

        SimpleAuthorizationInfo info = new SimpleAuthorizationInfo();
        //
        info.addRoles(user.roles);

        // 
        info.addStringPermissions(user.permissions);

        return info;
    }
}