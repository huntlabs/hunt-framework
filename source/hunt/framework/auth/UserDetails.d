module hunt.framework.auth.UserDetails;

import hunt.framework.auth.Claim;
import hunt.framework.auth.ClaimTypes;
import hunt.logging.ConsoleLogger;

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

    string fullName() {
        return claimAs!(string)(ClaimTypes.FullName);
    }

    void fullName(string value) {
        _claims ~= new Claim(ClaimTypes.FullName, value);
    }

    string[] roles;

    string[] permissions;

    Claim[] claims() {
        return _claims;
    }

    Variant claim(string type) {
        Variant v = Variant(null);

        foreach(Claim claim; _claims) {
            version(HUNT_AUTH_DEBUG) {
                tracef("type: %s, value: %s", claim.type, claim.value.toString());
            }
            if(claim.type == type) {
                v = claim.value();
                break;
            }
        }

        version(HUNT_DEBUG) {
            if(v == null || !v.hasValue()) {
                warningf("The claim for %s is null", type);
            }
        }

        return v;
    }

    T claimAs(T)(string type) {
        Variant v = claim(type);
        if(v == null || !v.hasValue()) {
            return T.init;
        }

        return v.get!T();
    }     

    void addClaim(T)(string type, T value) {
        _claims ~= new Claim(type, value);
    }

    override string toString() {
        return name;
    }

}
