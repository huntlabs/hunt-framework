module hunt.framework.auth.AuthRealm;

// import hunt.framework.auth.Claim;
// import hunt.framework.auth.ClaimTypes;
// import hunt.framework.auth.Identity;
// import hunt.framework.auth.JwtToken;
// import hunt.framework.auth.JwtUtil;
// import hunt.framework.auth.principal;
// import hunt.framework.auth.UserDetails;
import hunt.framework.auth.UserService;
// import hunt.framework.config.AuthUserConfig;
import hunt.framework.auth.AuthOptions;
// import hunt.framework.provider.ServiceProvider;


// import hunt.collection.ArrayList;
// import hunt.collection.Collection;
// import hunt.http.AuthenticationScheme;
// import hunt.logging.ConsoleLogger;
import hunt.shiro;
// import hunt.String;

// import std.algorithm;
// import std.range;
// import std.string;


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