module hunt.security.permission.Permission;

import hunt.security.permission.Item;

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