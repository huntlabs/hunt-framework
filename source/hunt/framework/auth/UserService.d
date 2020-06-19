module hunt.framework.auth.UserService;

import hunt.framework.auth.AuthUser;

/**
 * 
 */
interface UserService {

    bool authenticate(string name, string password);

    string getSalt(string name, string password);

    AuthUser getByName(string name);

    AuthUser getById(ulong id);
}