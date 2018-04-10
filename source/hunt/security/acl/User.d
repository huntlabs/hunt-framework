module hunt.security.User;

import hunt.security.Role;
import hunt.security.acl.permission.Permission;

class User
{
    private
    {
        int id;
        string name;
        Permission permission;
        Role role;
        Role[] roles;
    }

    public this(int userid, string username, Role role)
    {
        this.id = userid;
        this.name = username;
        this.role = role;

        this.permission = new Permission(role.permissions);
    }
    public int userId()
    {
        return this.id;
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
