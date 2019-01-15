module hunt.framework.security.acl.Manager;

import hunt.framework.security.acl.Role;
import hunt.framework.security.acl.User;
import hunt.framework.security.acl.Permission;
import hunt.framework.security.acl.AuthenticateProxy;
import hunt.logging;
import hunt.util.DateTime;
import hunt.cache;
import hunt.framework.http.Request;
import std.conv;


class AccessManager
{
public:    
    Role[] 			        roles;
	Permission[]            permissions;

private:
    AuthenticateProxy       auth;
    int                     updatedTick;

    UCache                  cache;
    string                  name;
    string                  prefix;
    int                     expired;                   
public:
    this(UCache cache , string name , string prefix , int expired)
    {
         this.cache = cache;
         this.name = name;
         this.prefix = prefix;
         this.expired = expired;
    }

    void initAuthenticateProxy(AuthenticateProxy auth)
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
        if(auth is null)
        {
            logError(" un set proxy for Manager");
            return null;
        }

        User user = getUser(id);
        if(user is null)
        {
            auto users = auth.getAllUsers([id]);
            if(users.length <= 0)
            {
                logError(" can't find id " , id);
                return null;
            }  
            user = users[0];
        }

        cache.put!User(prefix ~ name ~ "_user_" ~ to!string(id) , user , expired);
        int[] ids = cache.get!(int[])(prefix ~ name ~ "_userids");
        
        import std.algorithm.searching;
        auto f = find!("a == b")(ids , id);
        if(f.length == 0)
        {    
            ids ~= id;
        }
        cache.put!(int[])(prefix ~ name ~ "_userids" , ids , expired);
        logInfo(prefix ~ name ~ "_userids" , ids);
        auto session = request().session(true);
        session.set("auth_userid" , to!string(id));
        request().flush();

        return user;
    }

    User user() @property
    {
        auto session = request().session(true);
        if(!session.exists("auth_userid"))
        {
            return null;
        }
        auto id = to!int(session.get("auth_userid"));
        return getUser(id);
    }

    bool checkAuth()
    {
        if(user is null || ! user.can(request().getMCA()))
        {
            return false;
        }
        return true;
    }

    private User getUser(int id)
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
        if(updated >= updatedTick)
        {
            int[] ids = cache.get!(int[])(prefix ~ name ~ "_userids");
            this.permissions =  auth.getAllPermissions();
            this.roles = auth.getAllRoles();
            if(ids.length > 0)
            {
                auto users = auth.getAllUsers(ids);
                foreach(u ; users)
                {
                    cache.put!User(prefix ~ name ~ "_user_" ~ to!string(u.id) , u , expired);
                }
            }
            updatedTick = updated + 1;
        } 
    }

}
