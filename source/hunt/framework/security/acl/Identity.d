module hunt.framework.security.acl.Identity;

import hunt.framework.http.Request;
import hunt.framework.security.acl.User;

interface Identity
{
    // route group name, like: default / admin / api
    string group();

	bool isAllowAction(string persident);

	void addAllowAction(string persident);

    User login(Request);
}
