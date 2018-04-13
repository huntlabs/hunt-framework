module hunt.security.acl.Manager;

import hunt.security.acl.Role;

class AccessManager
{
    private
    {
        Role[int] roles;
    }

    public
    {
        Role createRole(int id, string name)
        {
            Role role = new Role;
            role.id = id;
            role.name = name;

            this.roles[id] = role;
        
            return role;
        }

        Role getRole(int id)
        {
            return this.roles[id];
        }
    }
}
