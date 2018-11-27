module hunt.framework.security.acl.Manager;

import hunt.framework.security.acl.Role;
import hunt.framework.security.acl.User;
import hunt.framework.security.acl.Permission;
import hunt.framework.security.acl.AuthenticateInterface;
import hunt.logging;
import hunt.datetime;
import hunt.cache;
//import hunt.framework.application.Application;
//import hunt.framework.application.AppConfig;

import std.conv;


class AccessManager
{
public:    
    Role[] 			        roles;
	Permission[]            permissions;

private:
    AuthenticateInterface   auth;
    int                     updatedTick;

    UCache                  cache;
    string                  name;
    string                  prefix;                   
public:
    this(UCache cache , string name , string prefix)
    {
         this.cache = cache;
         this.name = name;
         this.prefix = prefix;
    }

    void initAuthenticate(AuthenticateInterface auth)
    {
        this.auth = auth;
    }

    Permission getPermission(string key)
    {
        import std.algorithm.searching;
        auto per = find!(" a.key == b")(permissions , key);
        if(per.length > 0)
            return per[0];
        return null;
    }

    void refresh()
    {
        import core.stdc.time : time;
        cache.put!int(prefix ~ name ~ "_permissions" , cast(int)time(null));
    }

    User addUser(int id)
    {
        updataData();
        if(auth is null)
        {
            logError(" un set proxy for Manager");
            return null;
        }
        auto users = auth.getAllUsers([id]);
        if(users.length <= 0)
        {
            logError(" can't find id " , id);
            return null;
        }
        
        cache.put!User(prefix ~ name ~ "_user_" ~ to!string(id) , users[0]);
        int[] ids = cache.get!(int[])(prefix ~ name ~ "_userids");
        ids ~= id;
        cache.put!(int[])(prefix ~ name ~ "_userIds" , ids);

        return users[0];
    }

    User getUser(int id)
    {
        updataData();
        return cache.get!User(prefix ~ name ~ "_user_" ~ to!string(id));
    }

    private void updataData()
    {
        if(auth is null)
        {
            logError(" un set proxy for Manager");
            return;
        }

        auto updated = cache.get!int(prefix ~ name ~ "_permissions");
        if(updated > updatedTick)
        {
            int[] ids = cache.get!(int[])(prefix ~ name ~ "_userids");
            this.permissions =  auth.getAllPermissions();
            this.roles = auth.getAllRoles();
            auto users = auth.getAllUsers(ids);
            foreach(u ; users)
            {
                cache.put!User(prefix ~ name ~ "_user_" ~ to!string(u.id) , u);
            }
            updatedTick = updated;
        }
    }

}
