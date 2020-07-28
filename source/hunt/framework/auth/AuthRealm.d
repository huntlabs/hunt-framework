module hunt.framework.auth.AuthRealm;

import hunt.framework.auth.UserService;
import hunt.framework.auth.AuthOptions;
import hunt.shiro;


/**
 * See_also:
 *  [Springboot Integrate with Apache Shiro](http://www.andrew-programming.com/2019/01/23/springboot-integrate-with-jwt-and-apache-shiro/)
 *  https://stackoverflow.com/questions/13686246/shiro-security-multiple-realms-which-authorization-info-is-taken
 */
abstract class AuthRealm : AuthorizingRealm {
    string guardName() {
        return _guardName;
    }

    void guardName(string value) {
        _guardName = value;
    }
    private string _guardName = DEFAULT_GURAD_NAME;

    protected UserService getUserService();
}