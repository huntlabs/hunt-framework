module hunt.framework.middleware.BasicAuthMiddleware;

import hunt.framework.middleware.MiddlewareInterface;
import hunt.framework.middleware.AuthMiddleware;

import hunt.framework.auth.Claim;
import hunt.framework.auth.ClaimTypes;
import hunt.framework.auth.Identity;
import hunt.framework.auth.UserService;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.http.RedirectResponse;
import hunt.framework.http.Request;
import hunt.framework.http.Response;
import hunt.framework.http.UnauthorizedResponse;
import hunt.framework.provider.ServiceProvider;
import hunt.framework.Simplify;


import hunt.http.HttpHeader;
import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;
import hunt.shiro;

import std.base64;
import std.range;
import std.string;


/**
 * 
 */
class BasicAuthMiddleware : AuthMiddleware {
    
    shared static this() {
        MiddlewareInterface.register!(typeof(this));
    }

    this() {
        super();
    }

    this(RouteChecker routeChecker, MiddlewareEventHandler rejectionHandler) {
        super(routeChecker, rejectionHandler);
    }

    override protected UsernamePasswordToken getToken(Request request) {
        string tokenString = request.basicToken();
        if(tokenString.empty) {
            return null;
        }

        ubyte[] decoded = Base64.decode(tokenString);
        string[] values = split(cast(string)decoded, ":");
        if(values.length != 2) {
            warningf("Wrong token: %s", values);
            return null;
        }

        string username = values[0];
        string password = values[1];
        
        return new UsernamePasswordToken(username, password);
    }
}
