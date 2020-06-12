module hunt.framework.auth.AuthUser;

import hunt.framework.auth.AuthRole;

class AuthUser {
    int id;
    
    string name;
    
    string password;
    
    string fullName;

    AuthRole[] roles;
}
