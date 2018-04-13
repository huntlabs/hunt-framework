module hunt.security.authentication.Identity;

public import hunt.security.acl.User;

import hunt.http.request;

import std.variant;

interface Identity
{
    // route group name, like: default / admin / api
    string group();

    User login(Request);
}
