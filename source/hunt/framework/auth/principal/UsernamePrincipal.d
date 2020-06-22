module hunt.framework.auth.principal.UsernamePrincipal;

import hunt.security.Principal;

/**
 * 
 */
class UsernamePrincipal : Principal {

    private string _username;

    this(string username) {
        _username = username;
    }

    string getUsername() {
        return _username;
    }

    string getName() {
        return _username;
    }

    override string toString() {
        return _username;
    }
}
