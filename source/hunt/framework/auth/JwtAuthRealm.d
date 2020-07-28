module hunt.framework.auth.JwtAuthRealm;

import hunt.framework.auth.AuthRealm;
import hunt.framework.auth.Claim;
import hunt.framework.auth.ClaimTypes;
import hunt.framework.auth.Identity;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.JwtUtil;
import hunt.framework.auth.principal;
import hunt.framework.auth.UserDetails;
import hunt.framework.auth.UserService;
import hunt.framework.config.AuthUserConfig;
import hunt.framework.Init;
import hunt.framework.provider.ServiceProvider;


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
 *  https://stackoverflow.com/questions/13686246/shiro-security-multiple-realms-which-authorization-info-is-taken
 */
class JwtAuthRealm : AuthRealm {
    override bool supports(AuthenticationToken token) {
        version(HUNT_AUTH_DEBUG) tracef("AuthenticationToken: %s", typeid(cast(Object)token));
        
        JwtToken t = cast(JwtToken)token;
        return t !is null;
    }

    override protected UserService getUserService() {
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
            throw new AuthenticationException(format("The user [%s] does NOT exist!", username));
        }

        if(!user.isEnabled)
            throw new AuthenticationException("The user is disabled!");

        string salt = user.salt; // userService.getSalt(username, "user.password");
        version(HUNT_AUTH_DEBUG) {
            infof("tokenString: %s,  username: %s, salt: %s", tokenString, username, salt);
        }      

        // Valid the user using JWT
        if(!JwtUtil.verify(tokenString, username, salt)) {
            throw new IncorrectCredentialsException("Wrong username or password for " ~ username);
        }

        // Add claims
        Collection!(Object) principals = new ArrayList!(Object)(10);

        UserIdPrincipal idPrincipal = new UserIdPrincipal(user.id);
        principals.add(idPrincipal);

        UsernamePrincipal namePrincipal = new UsernamePrincipal(username);
        principals.add(namePrincipal);
        
        // AuthSchemePrincipal schemePrincipal = new AuthSchemePrincipal(AuthenticationScheme.Bearer);
        // principals.add(schemePrincipal);
        Claim claim;
        claim = new Claim(ClaimTypes.FullName, user.fullName);
        principals.add(claim);

        claim = new Claim(ClaimTypes.AuthScheme, cast(string)AuthenticationScheme.Bearer);
        principals.add(claim);

        foreach(Claim c; user.claims) {
            principals.add(c);
        }

        version(HUNT_AUTH_DEBUG) infof("Realm: %s", getName());

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

        version(HUNT_AUTH_DEBUG) trace(typeid(cast(Object)userService));
        trace(typeid(this));
        trace(typeid(cast(Object)userService));
        warning("vvvvv=>", getName());
        
        // To retrieve all the roles and permissions for the user from database
        UserDetails user = userService.getByName(username);
        if(user is null) {
            throw new AuthenticationException(format("The user [%s] does NOT exist!", username));
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