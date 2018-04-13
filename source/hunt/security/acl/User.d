module hunt.security.acl.User;

import hunt.security.acl.Role;
import hunt.security.acl.permission.Permission;

class User
{
    private
    {
        int _id;
        Permission _permission;
        Role role;
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

    public User assignRole(Role role)
    {
        this.roles ~= role;
        
        return this;
    }

    public string getRoleName()
    {
        return this.role.name;
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

    public bool hasPermission(string key)
    {
        return false;
    }
}
