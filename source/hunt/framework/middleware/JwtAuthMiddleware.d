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

    this() {
        super();
    }

    this(RouteChecker routeChecker, MiddlewareEventHandler rejectionHandler) {
        super(routeChecker, rejectionHandler);
    }

    override protected JwtToken getToken(Request request) {
        string tokenString = request.bearerToken();

        if(tokenString.empty)
            tokenString = request.cookie(BEARER_COOKIE_NAME);

        if(tokenString.empty)
            return null;
        return new JwtToken(tokenString);
    }

    // Response onProcess(Request request, Response response = null) {
    //     version(HUNT_AUTH_DEBUG) infof("path: %s, method: %s", request.path(), request.method );

    //     bool needCheck = true;
    //     if(_routeChecker !is null) {
    //         needCheck = _routeChecker(request.path(), request.getMethod());
    //     }

    //     if(!needCheck) {
    //         return null;
    //     }

    //     Subject subject = SecurityUtils.getSubject(guardName());
    //     if(subject.isAuthenticated()) {
    //         version(HUNT_DEBUG) {
    //             Identity user = request.auth().user();
    //             string fullName = user.claimAs!(string)(ClaimTypes.FullName);
    //             infof("User [%s / %s] logged in.",  user.name(), fullName);
    //         }
    //         return null;
    //     }
        
    //     JwtToken token = getToken(request);
            
    //     if(token !is null) {
    //         try {
    //             subject.login(token);
    //         } catch (AuthenticationException e) {
    //             version(HUNT_DEBUG) warning(e.msg);
    //             version(HUNT_AUTH_DEBUG) warning(e);
    //         } catch(Exception ex) {
    //             version(HUNT_DEBUG) warning(ex.msg);
    //             version(HUNT_AUTH_DEBUG) warning(ex);
    //         }

    //         if(subject.isAuthenticated()) {
    //             version(HUNT_DEBUG) {
    //                 Identity user = request.auth().user();
    //                 // Claim[] claims =  user.claims;
    //                 // foreach(Claim c; claims) {
    //                 //     tracef("%s, %s", c.type, c.value);
    //                 // }
    //                 string fullName = user.claimAs!(string)(ClaimTypes.FullName);
    //                 infof("User [%s / %s] logged in.",  user.name(), fullName);
    //             }
    //             return null;	
    //         }
    //     }
        
    //     return onRejected(request);
    // }
}