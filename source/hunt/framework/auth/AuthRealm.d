module hunt.framework.auth.AuthRealm;

import hunt.framework.auth.UserDetails;
import hunt.framework.auth.UserService;
import hunt.framework.auth.AuthOptions;
import hunt.framework.config.AuthUserConfig;
import hunt.shiro;

import hunt.collection.ArrayList;
import hunt.collection.Collection;
import hunt.http.AuthenticationScheme;

import std.algorithm;
import std.array;
import std.format;
import std.string;


/**
 * See_also:
 *  [Springboot Integrate with Apache Shiro](http://www.andrew-programming.com/2019/01/23/springboot-integrate-with-jwt-and-apache-shiro/)
 *  https://stackoverflow.com/questions/13686246/shiro-security-multiple-realms-which-authorization-info-is-taken
 */
abstract class AuthRealm : AuthorizingRealm {
    private string _guardName = DEFAULT_GURAD_NAME;
    private UserService _userService;

    this(UserService userService) {
        _userService = userService;
    }

    string guardName() {
        return _guardName;
    }

    void guardName(string value) {
        _guardName = value;
    }

    protected UserService getUserService() {
        return _userService; //serviceContainer().resolve!UserService();
    }

    override protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principals) {
        
        // To retrieve all the roles and permissions for the user from database
        UserDetails user = cast(UserDetails)principals.getPrimaryPrincipal();

        if(user is null) {
            throw new AuthenticationException(format("The user does NOT exist!"));
        }

        SimpleAuthorizationInfo authInfo = new SimpleAuthorizationInfo();
        //
        authInfo.addRoles(user.roles);

        // Try to convert all the custom permissions to shiro's ones
        string[] permissions = user.permissions.map!(p => p.strip().toShiroPermissions()).array;
        authInfo.addStringPermissions(permissions);

        return authInfo;
    }    
}