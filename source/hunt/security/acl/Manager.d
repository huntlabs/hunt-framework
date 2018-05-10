module hunt.security.acl.Manager;

import hunt.security.acl.Role;
import hunt.security.acl.Identity;
import hunt.security.acl.User;
import hunt.security.acl.permission.Permission;
import kiss.logger;

class AccessManager
{
    private
    {
        Role[int] 			roles;
		Identity[string]	identitys;
    }

    public
    {
		Role createRole(int id, string name , Permission permission)
		{
            Role role = new Role;
            role.id = id;
            role.name = name;
			role.permission = permission;
            this.roles[id] = role;
        
            return role;
        }

        Role getRole(int id)
        {
            return this.roles[id];
        }

		void addIdentity(Identity identity)
		{
			identitys[identity.group] = identity;
		}

		Identity getIdentity(string groupName)
		{
			if( groupName !in identitys)
				return null;
			return identitys[groupName];
		}

        User createUser(int id, string name)
        {
			return new User(id , name);
        }
    }
}
