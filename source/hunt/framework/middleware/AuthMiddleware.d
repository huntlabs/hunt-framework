module hunt.framework.middleware.AuthMiddleware;

import hunt.framework.middleware.MiddlewareInterface;

import hunt.framework.auth.AuthOptions;
import hunt.framework.auth.Claim;
import hunt.framework.auth.ClaimTypes;
import hunt.framework.auth.Identity;
import hunt.framework.auth.UserService;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.http.RedirectResponse;
import hunt.framework.http.Request;
import hunt.framework.http.Response;
import hunt.framework.http.UnauthorizedResponse;
import hunt.framework.Init;
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
abstract class AuthMiddleware : AbstractMiddleware {

    // this() {
    //     super();
    // }

    // this(RouteChecker routeChecker, MiddlewareEventHandler rejectionHandler) {
    //     super(routeChecker, rejectionHandler);
    // }

    protected AuthenticationToken getToken(Request request);

    protected bool onAccessable(Request request) {
        return true;
    }

    protected Response onRejected(Request request) {
        // if(_rejectionHandler !is null) {
        //     return _rejectionHandler(this, request);
        // } else {
            if(request.isRestful()) {
                return new UnauthorizedResponse();
            } else {
                ApplicationConfig.AuthConf appConfig = app().config().auth;
                string unauthorizedUrl = appConfig.unauthorizedUrl;
                return new RedirectResponse(request, unauthorizedUrl);
            }            
        // }
    } 

    Response onProcess(Request request, Response response = null) {
        version(HUNT_AUTH_DEBUG) {
            infof("path: %s, method: %s", request.path(), request.method );
        }

        // bool needCheck = true;
        // if(_routeChecker !is null) {
        //     needCheck = _routeChecker(request.path(), request.getMethod());
        // }

        // if(!needCheck) {
        //     return null;
        // }
        
        Identity user = request.auth().user();
        if(user.isAuthenticated()) {
            version(HUNT_DEBUG) {
                string fullName = user.fullName();
                infof("User [%s / %s] has already logged in.",  user.name(), fullName);
            }
            return null;
        }

        AuthenticationToken token = getToken(request);
        if(user.login(token)) {
            version(HUNT_DEBUG) {
                string fullName = user.fullName();
                infof("User [%s / %s] logged in.",  user.name(), fullName);
            }

            if(onAccessable(request)) return null;	
        }
        
        return onRejected(request);
    }    
}