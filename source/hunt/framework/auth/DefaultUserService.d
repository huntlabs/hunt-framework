module hunt.framework.auth.DefaultUserService;

import hunt.framework.auth.AuthUser;
import hunt.framework.auth.UserService;

import std.digest.sha;


/**
 * 
 */
class DefaultUserService : UserService {

    bool authenticate(string name, string password) {
        return false;
    }

    string getSalt(string name, string password) {
        string userSalt = name;
        auto sha256 = new SHA256Digest();
        ubyte[] hash256 = sha256.digest(password~userSalt);
        return toHexString(hash256);        
    }

    AuthUser getByName(string name) {
        return null;
    }

    AuthUser getById(ulong id) {
        return null;
    }
}