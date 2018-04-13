module hunt.security.acl.User;

import hunt.security.acl.Role;
import hunt.security.acl.permission.Permission;

class User
{
    private
    {
        int _id;
        Permission _permission;
        Role[] roles;
    }

    public this(int id)
    {
        this._id = id;
        this._permission = new Permission;
    }

    public int id()
    {
        return this._id;
    }

    public bool hasRole(int groupId)
    {
        return false;
    }

    public bool can(string key)
    {
        return this._permission.hasPermission(key);
    }

    public User assignRole(Role role)
    {
        this.roles ~= role;

        this._permission.addPermissions(role.permissions);
        
        return this;
    }

    public string[] getRoleNames()
    {
        string[] names;
        foreach(role; this.roles)
        {
            names ~= role.name;
        }

        return names;
    }
}
