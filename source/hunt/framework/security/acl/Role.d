module hunt.framework.security.acl.Role;

import hunt.framework.security.acl.Permission;

import hunt.framework.application.Application;

class Role
{
    int             id;
    string          name;
    Permission[]    permissions;

    this()
    {

    }

    this(int id , string name)
    {
        this.id = id;
        this.name = name;
    }

    bool can(string key )
    {
        import std.algorithm.searching;  
        return find!("a.key == b")(permissions , key).length > 0;
    }

    Role addPermissionIds(int[] permissionIds ... )
    {   
        import std.algorithm.searching;     
        auto permissions = app().accessManager.permissions;
        foreach(id ; permissionIds)
        {
            auto per = find!(" a.id == b")(permissions , id);
            if(per.length > 0)
                this.permissions ~= per[0];            
        }
        return this;
    }

}
