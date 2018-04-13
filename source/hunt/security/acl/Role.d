module hunt.security.acl.Role;

import hunt.security.acl.permission.Item;

class Role
{
    int id;
    string name;
    PermissionItem[string] permissions;
}
