module hunt.framework.middleware.JwtAuthMiddleware;

import hunt.framework.middleware.MiddlewareInterface;
import hunt.framework.middleware.AuthMiddleware;

import hunt.framework.application.Application;
import hunt.framework.auth;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.http.RedirectResponse;
import hunt.framework.http.Request;
import hunt.framework.http.Response;
import hunt.framework.http.UnauthorizedResponse;
import hunt.framework.Simplify;
import hunt.http.AuthenticationScheme;
import hunt.http.HttpHeader;
import hunt.logging.ConsoleLogger;
import hunt.shiro;

import std.range;
import std.string;


/**
 * 
 */
class JwtAuthMiddleware : AuthMiddleware {

    shared static this() {
        MiddlewareInterface.register!(typeof(this));
    }

    // this() {
    //     super();
    // }

    // this(RouteChecker routeChecker, MiddlewareEventHandler rejectionHandler) {
    //     super(routeChecker, rejectionHandler);
    // }

    override protected JwtToken getToken(Request request) {
        string tokenString = request.bearerToken();

        if(tokenString.empty)
            tokenString = request.cookie(BEARER_COOKIE_NAME);

        if(tokenString.empty)
            return null;
        return new JwtToken(tokenString);
    }
}