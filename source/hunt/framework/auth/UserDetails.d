module hunt.framework.auth.UserDetails;

/**
 * 
 */
class UserDetails {
    ulong id;

    string name;

    deprecated("This field will be removed in next release.")
    string password;

    string fullName;

    string[] roles;

    string[] permissions;
}