module hunt.framework.auth.SimpleUserService;

import hunt.framework.auth.UserDetails;
import hunt.framework.auth.UserService;

import hunt.framework.config.AuthUserConfig;
import hunt.framework.provider.ServiceProvider;
import hunt.logging;

import std.digest.sha;


/**
 * Retrieve user details from a local config file.
 */
class SimpleUserService : UserService {

    private AuthUserConfig _userConfig;

    this() {
        _userConfig = serviceContainer.resolve!(AuthUserConfig)();
    }

    private AuthUserConfig.Role getRole(string name) {
        foreach(AuthUserConfig.Role r; _userConfig.roles) {
            if(r.name == name) return r;
        }

        return null;
    }

    UserDetails authenticate(string name, string password) {
        
        foreach(AuthUserConfig.User user; _userConfig.users) {
            if(user.name != name || user.password != password)
                continue;

            UserDetails userDetails = new UserDetails();
            userDetails.name = name;
            // userDetails.password = password;
            userDetails.salt = getSalt(name, user.password);

            // roles
            foreach(string roleName; user.roles) {
                AuthUserConfig.Role role = getRole(roleName);
                if(role !is null) {
                    userDetails.roles ~= role.name;
                    userDetails.permissions ~= role.permissions;
                } else {
                    warning("The role is not defined: %s", roleName);
                }
            }
            
            return userDetails;
        }
        return null;
    }

    UserDetails getByName(string name) {
        foreach(AuthUserConfig.User user; _userConfig.users) {
            if(user.name != name) 
                continue;

            UserDetails userDetails = new UserDetails();
            userDetails.name = name;
            // userDetails.password = user.password;
            userDetails.salt = getSalt(name, user.password);

            // roles
            foreach(string roleName; user.roles) {
                AuthUserConfig.Role role = getRole(roleName);
                if(role !is null) {
                    userDetails.roles ~= role.name;
                    userDetails.permissions ~= role.permissions;
                } else {
                    warning("The role is not defined: %s", roleName);
                }
            }
            return userDetails;
        }
        return null;
    }

    UserDetails getById(ulong id) {
        return null;
    }

    string getSalt(string name, string password) {
        string userSalt = name;
        auto sha256 = new SHA256Digest();
        ubyte[] hash256 = sha256.digest(password~userSalt);
        return toHexString(hash256);        
    }

}