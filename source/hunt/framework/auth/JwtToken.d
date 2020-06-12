module hunt.framework.auth.JwtToken;

import hunt.shiro.authc.AuthenticationToken;

/**
 * 
 */
class JwtToken : AuthenticationToken {

    private string token;

    this(string token) {
        this.token = token;
    }

    string getPrincipal() {
        return token;
    }

    char[] getCredentials() {
        return cast(char[])token.dup;
    }
    
}