module hunt.framework.security.acl.permission.Permission;

import hunt.framework.security.acl.permission.Item;
import std.algorithm;
import kiss.logger;

class Permission
{
    PermissionItem[] permissions;

    public Permission addPermission(PermissionItem permission)
    {
		this.permissions ~= permission;
        return this;
    }

    public Permission addPermissions(PermissionItem[] permissions)
    {
		this.permissions ~= permissions;
			
		return this;
    }

    public bool hasPermission(string key)
    {
		logInfo(permissions , " key " , key);
		return find!(" a.key == b")(permissions , key).length > 0;
    }

	public Permission addPermission( string key , string name)
    {
		addPermission( PermissionItem( key , name));
        return this;
    }
}
