module hunt.framework.auth.JwtUtil;

import jwt;
import hunt.logging.ConsoleLogger;
import hunt.util.DateTime;

/**
 * 
 */
class JwtUtil {

    __gshared long EXPIRE_TIME = 5 * 60 * 1000;

    static bool verify(string token, string username, string secret) {
        try {
            Token tk = jwt.verify(token, secret, [JWTAlgorithm.HS256, JWTAlgorithm.HS512]);
            return true;
        } catch (Exception e) {
            warning(e.msg);
            version(HUNT_DEBUG) warning(e);
            return false;
        }
    }
    
    static string getUsername(string token) {
        try {
            Token tk = decode(token);
            return tk.claims().get("username");         
        } catch (Exception e) {
            warning(e);
            return null;
        }
    }

    static string sign(string username, string secret) {
        Token token = new Token(JWTAlgorithm.HS512);
        token.claims.exp = cast(int) DateTime.currentUnixTime() + EXPIRE_TIME;
        token.claims.set("username", username); 
        return token.encode(secret);
    }
    
}