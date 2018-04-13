module hunt.security.acl.permission.Permission;

import hunt.security.acl.permission.Item;

class Permission
{
    PermissionItem[string] permissions;

    public Permission addPermission(string key, PermissionItem permission)
    {
        this.permissions[key] = permission;

        return this;
    }

    public Permission addPermissions(PermissionItem[] permissions)
    {
        foreach(permission; permissions)
        {
            this.permissions[permission.key] = permission;
        }

        return this;
    }

    public bool hasPermission(string key)
    {
        return true;
    }

    public Permission create(string name, string key, string discription)
    {
        auto item = new PermissionItem(name, key, discription);

        return this;
    }
}