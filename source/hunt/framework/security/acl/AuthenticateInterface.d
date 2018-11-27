module hunt.framework.security.acl.AuthenticateInterface;
import hunt.framework.security.acl.Role;
import hunt.framework.security.acl.Permission;
import hunt.framework.security.acl.User;

///
interface AuthenticateInterface 
{
    Role[] getAllRoles();
    Permission[] getAllPermissions();
    User[] getAllUsers(int[] userIds);
}