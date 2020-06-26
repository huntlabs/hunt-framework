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
class JwtAuthMiddleware : MiddlewareInterface {

    private RouteChecker _couteChecker;

    this(RouteChecker handler = null) {
        _couteChecker = handler;
    }

    string name() {
        return typeof(this).stringof;
    }

    Response onProcess(Request request, Response response = null) {
        version(HUNT_SHIRO_DEBUG) infof("path: %s, method: %s", request.path(), request.method );

        bool needCheck = true;
        if(_couteChecker !is null) {
            needCheck = _couteChecker(request.path(), request.getMethod());
        }

        if(!needCheck) {
            return null;
        }

        Subject subject = SecurityUtils.getSubject();
        if(subject.isAuthenticated()) {
            version(HUNT_DEBUG) tracef("User %s has logged in.",  request.auth().user().name());
            return null;
        }
        
        ApplicationConfig.AuthConf appConfig = app().config().auth;
        string unauthorizedUrl = appConfig.unauthorizedUrl;
        
        string tokenString = request.bearerToken();
        if(tokenString.empty) {
            return new RedirectResponse(request, unauthorizedUrl);
        }

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

        return new RedirectResponse(request, unauthorizedUrl);        
    }
}