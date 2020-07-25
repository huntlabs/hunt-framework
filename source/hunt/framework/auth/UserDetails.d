module hunt.framework.auth.UserDetails;

import hunt.framework.auth.Claim;

import std.variant;

/**
 * 
 */
class UserDetails {
    ulong id;

    string name;

    bool isEnabled = true;

    deprecated("This field will be removed in next release.")
    string password;

    string salt;

    string fullName;

    string[] roles;

    string[] permissions;

    Claim[] claims;

    void addClaim(T)(string type, T value) {
        claims ~= new Claim(type, value);
    }

}
