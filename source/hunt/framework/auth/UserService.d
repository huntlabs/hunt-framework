module hunt.framework.auth.UserService;

import hunt.framework.auth.UserDetails;

/**
 * 
 */
interface UserService {

    UserDetails authenticate(string name, string password);

    // deprecated("This method will be removed in next release.")
    string getSalt(string name, string password);

    UserDetails getByName(string name);

    // deprecated("This method will be removed in next release.")
    UserDetails getById(ulong id);
}