module hunt.security.authentication.Authenticate;

import hunt.http.request;

public import hunt.security.authentication.Identity;
public import hunt.security.acl.User;

class Authenticate
{
    private
    {
        Identity _identity;
    }

    public Authenticate setIdentity(Identity identity)
    {
        this._identity = identity;

        return this;
    }

    public User login(Identity identity)
    {
        return null;
    }
}
