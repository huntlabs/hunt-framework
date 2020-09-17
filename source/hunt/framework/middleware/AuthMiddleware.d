module hunt.framework.middleware.AuthMiddleware;

import hunt.framework.middleware.MiddlewareInterface;

import hunt.framework.application.Application;
import hunt.framework.auth.Auth;
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

import std.base64;
import std.range;
import std.string;

/**
 * 
 */
class AuthMiddleware : AbstractMiddleware {
    shared static this() {
        MiddlewareInterface.register!(typeof(this));
    }

    protected bool onAccessable(Request request) {
        return true;
    }

    protected Response onRejected(Request request) {
        if(request.isRestful()) {
            return new UnauthorizedResponse("", true);
        } else {
            ApplicationConfig.AuthConf appConfig = app().config().auth;
            string unauthorizedUrl = appConfig.unauthorizedUrl;
            if(unauthorizedUrl.empty ) {
                return new UnauthorizedResponse("", false, request.auth().scheme());
            } else {
                return new RedirectResponse(request, unauthorizedUrl);
            }
        }            
    } 

    Response onProcess(Request request, Response response = null) {
        version(HUNT_AUTH_DEBUG) {
            infof("path: %s, method: %s", request.path(), request.method );
        }

        request.isAuthRequired = true;
        
        Auth auth = request.auth();
        if(!auth.isEnabled()) {
            warning("The auth is disabled. Are you sure that the guard is defined?");
            return onRejected(request);
        }

        // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-08-04T18:03:55+08:00
        // More tests are needed
        // Identity user = auth.user();
        // try {
        //     if(user.isAuthenticated()) {
        //         version(HUNT_DEBUG) {
        //             string fullName = user.fullName();
        //             infof("User [%s / %s] has already logged in.",  user.name(), fullName);
        //         }
        //         return null;
        //     }
        // } catch(Exception ex) {
        //     warning(ex.msg);
        //     version(HUNT_DEBUG) warning(ex);
        // }

        Identity user = auth.signIn();
        if(user.isAuthenticated()) {
            version(HUNT_DEBUG) {
                string fullName = user.fullName();
                infof("User [%s / %s] logged in.",  user.name(), fullName);
            }

            if(onAccessable(request)) return null;	
        }
        
        return onRejected(request);
    }    
}