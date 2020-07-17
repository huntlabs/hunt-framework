module hunt.framework.middleware.JwtAuthMiddleware;

import hunt.framework.middleware.MiddlewareInterface;

import hunt.framework.application.Application;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.JwtUtil;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.http.RedirectResponse;
import hunt.framework.http.Request;
import hunt.framework.http.Response;
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
class JwtAuthMiddleware : AbstractMiddleware!(JwtAuthMiddleware) {

    this() {
        super();
    }

    this(RouteChecker routeChecker, MiddlewareEventHandler rejectionHandler) {
        super(routeChecker, rejectionHandler);
    }

    private Response onRejected(Request request) {

        if(_rejectionHandler !is null) {
            return _rejectionHandler(this, request);
        } else {
            ApplicationConfig.AuthConf appConfig = app().config().auth;
            string unauthorizedUrl = appConfig.unauthorizedUrl;
            return new RedirectResponse(request, unauthorizedUrl);
        }
    }    

    Response onProcess(Request request, Response response = null) {
        version(HUNT_SHIRO_DEBUG) infof("path: %s, method: %s", request.path(), request.method );

        bool needCheck = true;
        if(_routeChecker !is null) {
            needCheck = _routeChecker(request.path(), request.getMethod());
        }

        if(!needCheck) {
            return null;
        }

        Subject subject = SecurityUtils.getSubject();
        if(subject.isAuthenticated()) {
            version(HUNT_DEBUG) tracef("User %s has logged in.",  request.auth().user().name());
            return null;
        }
        
        string tokenString = request.bearerToken();

        if(tokenString.empty)
            tokenString = request.cookie(BEARER_COOKIE_NAME);
            
        if(!tokenString.empty) {
            try {
                JwtToken token = new JwtToken(tokenString);
                subject.login(token);
            } catch (AuthenticationException e) {
                version(HUNT_DEBUG) warning(e.msg);
                version(HUNT_AUTH_DEBUG) warning(e);
            } catch(Exception ex) {
                version(HUNT_DEBUG) warning(ex.msg);
                version(HUNT_AUTH_DEBUG) warning(ex);
            }

            if(subject.isAuthenticated()) {
                version(HUNT_DEBUG) infof("User %s logged in.",  request.auth().user().name());
                return null;	
            }
        }
        
        return onRejected(request);
    }
}