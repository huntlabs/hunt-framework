module hunt.framework.auth.JwtUtil;

import hunt.framework.Init;

import jwt;
import hunt.logging.ConsoleLogger;
import hunt.util.DateTime;

import core.time;
import std.json;


/**
 * 
 */
class JwtUtil {

    __gshared Duration EXPIRE_TIME = days(DEFAULT_TOKEN_EXPIRATION);
    
    // enum string COOKIE_NAME = "__jwt_token__";

    static bool verify(string token, string username, string secret) {
        try {
            Token tk = jwt.verify(token, secret, [JWTAlgorithm.HS256, JWTAlgorithm.HS512]);
            return true;
        } catch (Exception e) {
            version(HUNT_DEBUG) warning(e.msg);
            version(HUNT_SHIRO_DEBUG) warning(e);
            return false;
        }
    }
    
    static string getUsername(string token) {
        try {
            Token tk = decode(token);
            return tk.claims().sub();
        } catch (Exception e) {
            warning(e);
            return null;
        }
    }

    static string sign(string username, string secret) {
        return sign(username, secret, EXPIRE_TIME);
    }
    
    static string sign(string username, string secret, string[string] claims) {
        return sign(username, secret, EXPIRE_TIME, claims);
    }

    static string sign(string username, string secret, Duration expireTime, string[string] claims = null) {
        JSONValue claimsInJson = JSONValue(claims);
        return sign(username, secret, expireTime, claimsInJson);
    }

    static string sign(string username, string secret, Duration expireTime, JSONValue claims) {
        version(HUNT_AUTH_DEBUG) infof("username: %s, salt: %s", username, secret);
        Token token = new Token(JWTAlgorithm.HS512);
        token.claims.sub = username;
        token.claims.exp = cast(int) DateTime.currentUnixTime() + expireTime.total!(TimeUnit.Second)();
        // token.claims.set("username", username);

        foreach(string key, JSONValue value; claims) {
            token.claims.set(key, value);
        }

        return token.encode(secret);        
    }
}