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

    override bool supports(AuthenticationToken token) {
        version(HUNT_AUTH_DEBUG) tracef("AuthenticationToken: %s", typeid(cast(Object)token));
        UsernamePasswordToken t = cast(UsernamePasswordToken)token;
        return t !is null;
    }

    override protected UserService getUserService() {
        return serviceContainer().resolve!UserService();
    }

    override protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken token) {
        string username = token.getPrincipal();
        string password = cast(string)token.getCredentials();

        UserService userService = getUserService();
        version(HUNT_AUTH_DEBUG) {
            infof("username: %s, %s", username, typeid(cast(Object)userService));
        }        

            infof("username: %s, %s", username, typeid(cast(Object)userService));

        // To authenticate the user with username and password
        UserDetails user = userService.authenticate(username, password);
        
        if(user !is null) {
            // Collection!(Object) principals = new ArrayList!(Object)(3);

            // // Add claims
            // Claim claim;
            // UserIdPrincipal idPrincipal = new UserIdPrincipal(user.id);
            // principals.add(idPrincipal);

            // UsernamePrincipal namePrincipal = new UsernamePrincipal(username);
            // principals.add(namePrincipal);

            // claim = new Claim(ClaimTypes.FullName, user.fullName);
            // principals.add(claim);

            // claim = new Claim(ClaimTypes.AuthScheme, cast(string)AuthenticationScheme.Basic);
            // principals.add(claim);
            // // AuthSchemePrincipal schemePrincipal = new AuthSchemePrincipal(AuthenticationScheme.Basic);
            // // principals.add(schemePrincipal);

            // foreach(Claim c; user.claims) {
            //     principals.add(c);
            // }

            version(HUNT_AUTH_DEBUG) infof("Realm: %s", getName());
            PrincipalCollection pCollection = new SimplePrincipalCollection(user, getName());
            String credentials = new String(password);
            SimpleAuthenticationInfo info = new SimpleAuthenticationInfo(pCollection, credentials);

            return info;
        } else {
            throw new IncorrectCredentialsException(username);
        }
    }

    // override protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principals) {

    //     // SimplePrincipalCollection spc = cast(SimplePrincipalCollection)principals;
        
    //     // UsernamePrincipal principal = spc.oneByType!(UsernamePrincipal)();
    //     // if(principal is null) {
    //     //     warning("No username avaliable");
    //     //     return null;
    //     // }
    //     // version(HUNT_AUTH_DEBUG) tracef("Realm: %s", getName());

    //     // string username = principal.getUsername();

    //     // UserService userService = getUserService();
    //     // version(HUNT_AUTH_DEBUG) {
    //     //     trace(typeid(this));
    //     //     trace(typeid(cast(Object)userService));
    //     // }

    //     // UserDetails user = userService.getByName(username);

    //     // To retrieve all the roles for the user from database
    //     UserDetails user = cast(UserDetails)principals.getPrimaryPrincipal();

    //     if(user is null) {
    //         throw new AuthenticationException(format("The user does NOT exist!"));
    //     }

    //     SimpleAuthorizationInfo info = new SimpleAuthorizationInfo();
    //     //
    //     info.addRoles(user.roles);

    //     // 
    //     info.addStringPermissions(user.permissions);


    //     return info;
    // }
}