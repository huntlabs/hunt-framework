module hunt.security.acl.permission.Permission;

import hunt.security.acl.permission.Item;

class Permission
{
    PermissionItem[string] permissions;

    public this(PermissionItem[] permissions)
    {
        this.permissions = permissions;
    }

    public Permission create(string name, string key, string discription)
    {
        auto item = new PermissionItem(name, key, discription);

        return this;
    }
}