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

        // string tokenString = request.bearerToken();

        // if(tokenString.empty)
        //     tokenString = request.cookie(BEARER_COOKIE_NAME);

        // if(tokenString.empty)
        //     return null;
        // return new JwtToken(tokenString);
    }

    // protected string getSalt(string username) {
    //     UserService userService = serviceContainer().resolve!UserService();
    //     string salt = userService.getSalt(username, "");
    //     return salt;
    // }

    ///return null is continue, response is close the session
    // Response onProcess(Request request, Response response = null) {
    //     version(HUNT_AUTH_DEBUG) infof("path: %s, method: %s", request.path(), request.method );

    //     bool needCheck = true;
    //     if (_routeChecker !is null) {
    //         needCheck = _routeChecker(request.path(), request.getMethod());
    //     }

    //     if (!needCheck) {
    //         return null;
    //     }

    //     Subject subject = SecurityUtils.getSubject(guardName());
    //     if (subject.isAuthenticated()) {
    //         version (HUNT_DEBUG) {
    //             Identity user = request.auth().user();
    //             string fullName = user.claimAs!(string)(ClaimTypes.FullName);
    //             infof("User [%s / %s] logged in.",  user.name(), fullName);
    //         }
    //         return null;
    //     }

    //     string tokenString = request.basicToken();
    //     if(tokenString.empty) {
    //         return onRejected(request);
    //     }

    //     ubyte[] decoded = Base64.decode(tokenString);
    //     string[] values = split(cast(string)decoded, ":");
    //     if(values.length != 2) {
    //         warningf("Wrong token: %s", values);
    //         return onRejected(request);
    //     }

    //     string username = values[0];
    //     string password = values[1];

    //     Identity user = request.auth().signIn(username, password, getSalt(username));
    //     if(user.isAuthenticated()) {
    //         version(HUNT_DEBUG) {
    //             // Claim[] claims =  user.claims;
    //             // foreach(Claim c; claims) {
    //             //     tracef("%s, %s", c.type, c.value);
    //             // }
    //             string fullName = user.claimAs!(string)(ClaimTypes.FullName);
    //             infof("User [%s / %s] logged in.",  user.name(), fullName);
    //         }
    //         return null;
    //     } else {
    //         return onRejected(request);
    //     }
    // }
}
