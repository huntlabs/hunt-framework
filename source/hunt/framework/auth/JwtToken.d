module hunt.framework.auth.JwtToken;

import hunt.shiro.authc.AuthenticationToken;


/**
 * 
 */
class JwtToken : AuthenticationToken {

    private string _token;
    private string _name;

    this(string token, string name = DEFAULT_AUTH_TOKEN_NAME) {
        _token = token;
        _name = name;
    }

    string getPrincipal() {
        return _token;
    }

    char[] getCredentials() {
        return cast(char[])_token.dup;
    }

    string name() {
        return _name;
    }
}