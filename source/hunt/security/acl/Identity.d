module hunt.security.acl.Identity;

import hunt.http.request;
import hunt.security.acl.User;

interface Identity
{
    // route group name, like: default / admin / api
    string group();

    User login(Request);
}
