module hunt.security.authentication.Identity;

public import hunt.security.acl.User;
public import hunt.http.request;

interface Identity
{
    // route group name, like: default / admin / api
    string group();

    User login(Request);
}
