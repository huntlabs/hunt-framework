module hunt.framework.auth.JwtAuthRealm;

import hunt.framework.auth.Claim;
import hunt.framework.auth.ClaimTypes;
import hunt.framework.auth.Identity;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.JwtUtil;
import hunt.framework.auth.principal;
import hunt.framework.auth.UserDetails;
import hunt.framework.auth.UserService;
import hunt.framework.provider.ServiceProvider;

import hunt.framework.config.AuthUserConfig;

import hunt.collection.ArrayList;
import hunt.collection.Collection;
import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;
import hunt.shiro;
import hunt.String;

import std.algorithm;
import std.range;
import std.string;


/**
 * See_also:
 *  [Springboot Integrate with Apache Shiro](http://www.andrew-programming.com/2019/01/23/springboot-integrate-with-jwt-and-apache-shiro/)
 */
class JwtAuthRealm : AuthorizingRealm {
    // private UserService userService;

    this() {
        // userService = serviceContainer().resolve!UserService();
    }

    override bool supports(AuthenticationToken token) {
        // return typeid(cast(Object)token) == typeid(JwtToken);
        
        JwtToken t = cast(JwtToken)token;
        if(t is null)
            return false;
        return t.name() ==  DEFAULT_AUTH_TOKEN_NAME;
    }

    protected UserService getUserService() {
        return serviceContainer().resolve!UserService();
    }

    override protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken token) {
        string tokenString = token.getPrincipal();
        string username = JwtUtil.getUsername(tokenString);
        if (username.empty) {
            version(HUNT_DEBUG) warning("The username in token is empty.");
            throw new AuthenticationException("token invalid");
        }

        UserService userService = getUserService();
        version(HUNT_AUTH_DEBUG) {
            infof("username: %s, %s", username, typeid(cast(Object)userService));
        }        

        // To retrieve the user info from username
        UserDetails user = userService.getByName(username);
        if(user is null) {
            throw new AuthenticationException("The user does NOT exist!");
        }

        if(!user.isEnabled)
            throw new AuthenticationException("The user is disabled!");

        string salt = user.salt; // userService.getSalt(username, "user.password");
        version(HUNT_AUTH_DEBUG) {
            infof("tokenString: %s,  username: %s, salt: %s", tokenString, username, salt);
        }      
            infof("tokenString: %s,  username: %s, salt: %s", tokenString, username, salt);    

        // Valid the user using JWT
        if(!JwtUtil.verify(tokenString, username, salt)) {
            throw new IncorrectCredentialsException("Wrong username or password for " ~ username);
        }

        // Add claims
        Claim claim;
        
        Collection!(Object) principals = new ArrayList!(Object)(10);

        UserIdPrincipal idPrincipal = new UserIdPrincipal(user.id);
        principals.add(idPrincipal);

        UsernamePrincipal namePrincipal = new UsernamePrincipal(username);
        principals.add(namePrincipal);
        
        // AuthSchemePrincipal schemePrincipal = new AuthSchemePrincipal(AuthenticationScheme.Bearer);
        // principals.add(schemePrincipal);

        claim = new Claim(ClaimTypes.AuthScheme, cast(string)AuthenticationScheme.Bearer);
        principals.add(claim);

        foreach(Claim c; user.claims) {
            principals.add(c);
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

        UserService userService = getUserService();
        string username = principal.getUsername();
        
        // To retrieve all the roles and permissions for the user from database
        UserDetails user = userService.getByName(username);
        if(user is null) {
            throw new AuthenticationException("User didn't existed!");
        }

        SimpleAuthorizationInfo info = new SimpleAuthorizationInfo();
        //
        info.addRoles(user.roles);

        // 
        string[] permissions = user.permissions.map!(p => p.strip().toShiroPermissions()).array;
        info.addStringPermissions(permissions);

        return info;
    }
}