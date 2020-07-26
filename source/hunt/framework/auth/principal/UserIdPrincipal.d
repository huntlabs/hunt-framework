module hunt.framework.auth.principal.UserIdPrincipal;

import hunt.security.Principal;
import std.conv;

/**
 * 
 */
class UserIdPrincipal : Principal {

    private ulong _userId;

    this(ulong userId) {
        this._userId = userId;
    }

    ulong getUserId() {
        return _userId;
    }

    string getName() {
        return _userId.to!string();
    }

    override string toString() {
        return _userId.to!string();
    }
}