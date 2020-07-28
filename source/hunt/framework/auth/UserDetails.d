module hunt.framework.auth.UserDetails;

import hunt.framework.auth.Claim;

import std.variant;

/**
 * 
 */
class UserDetails {
    private Claim[] _claims;
    ulong id;

    string name;

    bool isEnabled = true;

    deprecated("This field will be removed in next release.")
    string password;

    string salt;

    string fullName;

    string[] roles;

    string[] permissions;

    Claim[] claims() {
        return _claims;
    }

    void addClaim(T)(string type, T value) {
        _claims ~= new Claim(type, value);
    }

    override string toString() {
        return name;
    }

}
