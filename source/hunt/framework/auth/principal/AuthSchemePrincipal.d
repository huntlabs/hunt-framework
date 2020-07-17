module hunt.framework.auth.principal.AuthSchemePrincipal;

import hunt.http.AuthenticationScheme;

import hunt.security.Principal;
import std.conv;


/**
 * 
 */
class AuthSchemePrincipal : Principal {

    private AuthenticationScheme _authScheme;

    this(AuthenticationScheme scheme) {
        this._authScheme = scheme;
    }

    AuthenticationScheme getAuthScheme() {
        return _authScheme;
    }

    string getName() {
        return _authScheme.to!string();
    }
}