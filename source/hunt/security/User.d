module hunt.security.User;

import hunt.security.Role;

class User
{
    private
    {
        int id;
        string name;
        Role role;
        Role[] roles;
    }

    public this(int userid, string username, Role role)
    {
        this.id = userid;
        this.name = username;
        this.role = role;
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
}
