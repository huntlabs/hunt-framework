module hunt.framework.auth.JwtUtil;

import hunt.framework.auth.AuthOptions;
import hunt.framework.jwt;
import hunt.logging.ConsoleLogger;
import hunt.util.DateTime;

import core.time;
import std.json;


/**
 * 
 */
class JwtUtil {

    __gshared Duration EXPIRE_TIME = days(DEFAULT_TOKEN_EXPIRATION);

    static bool verify(string token, string username, string secret) {
        try {
            return hunt.framework.jwt.verify(token, secret);
        } catch (Exception e) {
            warning(e.msg);
            version(HUNT_AUTH_DEBUG) warning(e);
            return false;
        }
    }
    
    static string getUsername(string token) {
        try {
            Token tk = decodeAsToken(token);
            return tk.claims().sub();
        } catch (Exception e) {
            warning(e);
            return null;
        }
    }

    static string sign(string username, string secret, JWTAlgorithm algo = JWTAlgorithm.HS512) {
        return sign(username, secret, EXPIRE_TIME, null, algo);
    }
    
    static string sign(string username, string secret, string[string] claims, JWTAlgorithm algo = JWTAlgorithm.HS512) {
        return sign(username, secret, EXPIRE_TIME, claims, algo);
    }

    static string sign(string username, string secret, Duration expireTime, 
            string[string] claims = null, JWTAlgorithm algo = JWTAlgorithm.HS512) {
        JSONValue claimsInJson = JSONValue(claims);
        return sign(username, secret, expireTime, claimsInJson, algo);
    }

    static string sign(string username, string secret, Duration expireTime, 
            JSONValue claims, JWTAlgorithm algo = JWTAlgorithm.HS512) {
        version(HUNT_AUTH_DEBUG) {
            infof("username: %s, secret: %s", username, secret);
        }

        Token token = new Token(algo);
        token.claims.sub = username;
        token.claims.exp = cast(int) DateTime.currentUnixTime() + expireTime.total!(TimeUnit.Second)();
        // token.claims.set("username", username);

        foreach(string key, JSONValue value; claims) {
            token.claims.set(key, value);
        }

        return token.encode(secret);        
    }
}