module hunt.framework.auth.guard.BasicGuard;

import hunt.framework.auth.guard.Guard;
import hunt.framework.auth.AuthOptions;
import hunt.framework.auth.BasicAuthRealm;
import hunt.framework.auth.JwtAuthRealm;
import hunt.framework.auth.SimpleUserService;
import hunt.framework.auth.UserService;
import hunt.framework.http.Request;
import hunt.http.AuthenticationScheme;
import hunt.shiro;

import hunt.logging.Logger;

import std.algorithm;
import std.base64;
import std.range;
import std.string;


class BasicGuard : Guard {

    this() {
        this(new SimpleUserService(), DEFAULT_GURAD_NAME);
    }

    this(UserService userService, string name) {
        super(userService, name);
        initialize();
    }    

    override AuthenticationToken getToken(Request request) {
        string tokenString = request.basicToken();
        
        if (tokenString.empty)
            tokenString = request.cookie(tokenCookieName);

        if(tokenString.empty) {
            return null;
        }

        ubyte[] decoded = Base64.decode(tokenString);
        string[] values = split(cast(string)decoded, ":");
        if(values.length != 2) {
            warningf("Wrong token: %s", values);
            return null;
        }

        string username = values[0];
        string password = values[1];
        
        return new UsernamePasswordToken(username, password);
    }

    protected void initialize() {
        tokenCookieName = BASIC_COOKIE_NAME;
        authScheme = AuthenticationScheme.Basic;

        addRealms(new BasicAuthRealm(userService()));
        // addRealms(new JwtAuthRealm(userService()));
    }

}