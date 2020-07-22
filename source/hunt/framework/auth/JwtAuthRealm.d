module hunt.framework.auth.JwtAuthRealm;

import hunt.framework.auth.Claim;
import hunt.framework.auth.Identity;
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
            version(HUNT_DEBUG) warning("The username in token is empty.");
            throw new AuthenticationException("token invalid");
        }

        // To retrieve the user info from username
        UserDetails user = _userService.getByName(username);
        if(user is null) {
            throw new AuthenticationException("The user doesn't exist!");
        }

        string salt = _userService.getSalt(username, "user.password");
        version(HUNT_SHIRO_DEBUG) {
            infof("tokenString: %s,  username: %s, salt: %s", tokenString, username, salt);
        }          

        // Valid the user using JWT
        if(!JwtUtil.verify(tokenString, username, salt)) {
            throw new IncorrectCredentialsException("Wrong username or password for " ~ username);
        }

        
        Collection!(Object) principals = new ArrayList!(Object)(3);

        UserIdPrincipal idPrincipal = new UserIdPrincipal(user.id);
        principals.add(idPrincipal);

        UsernamePrincipal namePrincipal = new UsernamePrincipal(username);
        principals.add(namePrincipal);
        
        AuthSchemePrincipal schemePrincipal = new AuthSchemePrincipal(AuthenticationScheme.Bearer);
        principals.add(schemePrincipal);

        foreach(Claim claim; user.claims) {
            principals.add(claim);
        }

        PrincipalCollection pCollection = new SimplePrincipalCollection(principals, getName());
        String credentials = new String(tokenString);

        SimpleAuthenticationInfo info = new SimpleAuthenticationInfo(pCollection, credentials);
        return info;
    }

    override protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principals) {
        SimplePrincipalCollection spc = cast(SimplePrincipalCollection)principals;
        
        UsernamePrincipal principal = spc.oneByType!(UsernamePrincipal)();
        if(principal is null) {
            warning("No username avaliable");
            return null;
        }

        string username = principal.getUsername();
        
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