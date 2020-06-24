module hunt.framework.auth.UserAuthRealm;

import hunt.framework.auth.JwtToken;
import hunt.framework.auth.JwtUtil;
import hunt.framework.auth.principal;
import hunt.framework.auth.UserDetails;
import hunt.framework.auth.UserService;
import hunt.framework.provider.ServiceProvider;

import hunt.collection.ArrayList;
import hunt.collection.Collection;
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

        version(HUNT_SHIRO_DEBUG) {
            infof("username: %s", username);
        }        

        // To authenticate the user with username and password
        UserDetails user = _userService.authenticate(username, password);
        
        if(user !is null) {
            Collection!(Object) principals = new ArrayList!(Object)(3);

            UserIdPrincipal idPrincipal = new UserIdPrincipal(user.id);
            principals.add(idPrincipal);

            UsernamePrincipal namePrincipal = new UsernamePrincipal(username);
            principals.add(namePrincipal);

            String credentials = new String(password);

            PrincipalCollection pCollection = new SimplePrincipalCollection(principals, getName());
            SimpleAuthenticationInfo info = new SimpleAuthenticationInfo(pCollection, credentials);

            return info;
        } else {
            throw new IncorrectCredentialsException(username);
        }
    }

    override protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principals) {
        SimplePrincipalCollection spc = cast(SimplePrincipalCollection)principals;
        
        UsernamePrincipal principal = spc.oneByType!(UsernamePrincipal)();
        if(principal is null) {
            warning("No username avaliable");
            return null;
        }

        string username = principal.getUsername();
        SimpleAuthorizationInfo info = new SimpleAuthorizationInfo();

        // To retrieve all the roles for the user from database
        UserDetails user = _userService.getByName(username);
        if(user is null) {
            throw new AuthenticationException("User didn't existed!");
        }

        //
        info.addRoles(user.roles);

        // 
        info.addStringPermissions(user.permissions);


        return info;
    }
}