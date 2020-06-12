module hunt.framework.auth.UserService;

import hunt.framework.auth.AuthUser;

/**
 * 
 */
interface UserService {

    AuthUser authenticate(string name, string password);

    AuthUser getByName(string name);

    AuthUser getById(ulong id);
}