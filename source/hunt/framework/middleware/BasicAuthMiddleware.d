module hunt.framework.middleware.BasicAuthMiddleware;

import hunt.framework.middleware.MiddlewareInterface;

import hunt.framework.auth.Identity;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.http.RedirectResponse;
import hunt.framework.http.Request;
import hunt.framework.http.Response;
import hunt.framework.http.UnauthorizedResponse;
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
class BasicAuthMiddleware : AbstractMiddleware!(BasicAuthMiddleware) {

    this() {
        super();
    }

    this(RouteChecker routeChecker, MiddlewareEventHandler rejectionHandler) {
        super(routeChecker, rejectionHandler);
    }

    protected Response onRejected(Request request) {
        if(request.isRestful()) {
            return new UnauthorizedResponse();
        } else {
            ApplicationConfig.AuthConf appConfig = app().config().auth;
            string unauthorizedUrl = appConfig.unauthorizedUrl;
            return new RedirectResponse(request, unauthorizedUrl);
        }
        // if(_rejectionHandler !is null) {
        //     return _rejectionHandler(this, request);
        // } else {
        //     ApplicationConfig.AuthConf appConfig = app().config().auth;
        //     string unauthorizedUrl = appConfig.unauthorizedUrl;
        //     return new RedirectResponse(request, unauthorizedUrl);
        // }
    }    

    ///return null is continue, response is close the session
    Response onProcess(Request request, Response response = null) {
        infof("path: %s, method: %s", request.path(), request.method);

        bool needCheck = true;
        if (_routeChecker !is null) {
            needCheck = _routeChecker(request.path(), request.getMethod());
        }

        if (!needCheck) {
            return null;
        }

        Subject subject = SecurityUtils.getSubject();
        if (subject.isAuthenticated()) {
            version (HUNT_DEBUG)
                tracef("User %s has logged in.", request.auth().user().name());
            return null;
        }

        ApplicationConfig.AuthConf appConfig = app().config().auth;
        string unauthorizedUrl = appConfig.unauthorizedUrl;

        string tokenString = request.basicToken();
        if(tokenString.empty) {
            return onRejected(request);
        }

        ubyte[] decoded = Base64.decode(tokenString);
        string[] values = split(cast(string)decoded, ":");
        if(values.length != 2) {
            warningf("Wrong token: %s", values);
            return onRejected(request);
        }

        string username = values[0];
        string password = values[1];

        Identity user = request.auth().signIn(username, password);
        if(user.isAuthenticated()) {
            return null;
        } else {
            return onRejected(request);
        }
    }
}
