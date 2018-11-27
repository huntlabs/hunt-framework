module hunt.framework.security.acl.AuthenticateProxy;
import hunt.framework.security.acl.Role;
import hunt.framework.security.acl.Permission;
import hunt.framework.security.acl.User;

///
interface AuthenticateProxy 
{
    Role[] getAllRoles();
    Permission[] getAllPermissions();
    User[] getAllUsers(int[] userIds);
}