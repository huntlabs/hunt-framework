module hunt.framework.auth.UserService;

import hunt.framework.auth.UserDetails;

/**
 * 
 */
interface UserService {

    bool authenticate(string name, string password);

    string getSalt(string name, string password);

    UserDetails getByName(string name);

    UserDetails getById(ulong id);
}