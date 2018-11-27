module hunt.framework.security.acl.User;

import hunt.framework.security.acl.Role;
import hunt.framework.security.acl.Permission;
import hunt.framework.application.Application;

class User
{   
    int                     id;
    Role[]                  roles;

    this()
    {

    }

    bool can(string key)
    {
        import std.algorithm.searching;
        foreach(r ; roles)
        {
            if(r.can(key))
                return true;
        }
        return false;
    }

    User addRoleIds(int[] roleIds ... )
    {
        import std.algorithm.searching;
        auto roles = app().accessManager.roles;
        foreach(id ; roleIds)
        {
            auto role = find!(" a.id == b")(roles , id);
            if(role.length > 0)
                this.roles ~= role[0];
        }
        return this;
    } 


}
