module hunt.security.Role;

import hunt.security.permission.Item;

class Role
{
    int id;
    string name;
    PermissionItem[string] permissions;
}
