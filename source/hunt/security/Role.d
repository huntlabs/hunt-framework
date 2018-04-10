module hunt.security.Role;

import hunt.security.permission.Permission;

class Role
{
    int id;
    string name;
    Permission[string] permissions;
}
