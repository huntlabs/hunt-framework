module hunt.framework.auth.guard.JwtGuard;

import hunt.framework.auth.guard.Guard;
import hunt.framework.auth.AuthOptions;
import hunt.framework.auth.BasicAuthRealm;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.JwtAuthRealm;
import hunt.framework.auth.SimpleUserService;
import hunt.framework.auth.UserService;
import hunt.framework.http.Request;
import hunt.http.AuthenticationScheme;
import hunt.shiro;

import hunt.logging.ConsoleLogger;

import std.algorithm;
import std.base64;
import std.range;
import std.string;


class JwtGuard : Guard {

    this() {
        this(new SimpleUserService(), DEFAULT_GURAD_NAME);
    }

    this(UserService userService, string name) {
        super(userService, name);
        initialize();
    }    

    override AuthenticationToken getToken(Request request) {
        string tokenString = request.bearerToken();
        // string tokenCookieName = request.auth().tokenCookieName(); // authOptions.tokenCookieName;

        if (tokenString.empty)
            tokenString = request.cookie(tokenCookieName);

        if (tokenString.empty)
            return null;

        return new JwtToken(tokenString, tokenCookieName);
    }

    protected void initialize() {
        tokenCookieName = JWT_COOKIE_NAME;
        authScheme = AuthenticationScheme.Bearer;

        addRealms(new BasicAuthRealm(userService()));
        addRealms(new JwtAuthRealm(userService()));
    }
}
