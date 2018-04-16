module hunt.security.acl.permission.Permission;

import hunt.security.acl.permission.Item;

class Permission
{
    PermissionItem[string] permissions;

    public Permission addPermission(PermissionItem permission)
    {
		this.permissions[permission.key] = permission;

        return this;
    }

    public Permission addPermissions(PermissionItem[string] permissions)
    {
        foreach(permission; permissions)
        {
			addPermission(permission);
        }

        return this;
    }

    public bool hasPermission(string key)
    {
		return (key in permissions) != null;
    }

	public Permission addPermission(string name, string key)
    {
		addPermission( PermissionItem(name, key));
        return this;
    }
}
