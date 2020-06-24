module hunt.framework.middleware.BasicAuthMiddleware;

import hunt.framework.middleware.MiddlewareInterface;

import hunt.framework.auth.Identity;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.http.RedirectResponse;
import hunt.framework.http.Request;
import hunt.framework.http.Response;
import hunt.framework.Simplify;
import hunt.http.HttpHeader;
import hunt.logging.ConsoleLogger;
import hunt.shiro;

import std.base64;
import std.range;
import std.string;

/**
 * 
 */
class BasicAuthMiddleware : MiddlewareInterface {
    
    enum TokenHeader = "Basic ";
    private RouteChecker _couteChecker;

    this(RouteChecker handler = null) {
        _couteChecker = handler;
    }

    string name() {
        return typeof(this).stringof;
    }

    ///return null is continue, response is close the session
    Response onProcess(Request request, Response response = null) {
        infof("path: %s, method: %s", request.path(), request.method);

        bool needCheck = true;
        if (_couteChecker !is null) {
            needCheck = _couteChecker(request.path(), request.getMethod());
        }

        if (!needCheck) {
            return null;
        }

        Subject subject = SecurityUtils.getSubject();
        if (subject.isAuthenticated()) {
            version (HUNT_DEBUG)
                tracef("User %s has logged in.", request.user.name());
            return null;
        }

        ApplicationConfig.AuthConf appConfig = app().config().auth;
        string unauthorizedUrl = appConfig.unauthorizedUrl;

        string tokenString = request.basicToken();
        if(tokenString.empty()) {
            return new RedirectResponse(request, unauthorizedUrl);
        }

        ubyte[] decoded = Base64.decode(tokenString);
        string[] values = split(cast(string)decoded, ":");
        if(values.length != 2) {
            warningf("Wrong format: %s", values);
            return new RedirectResponse(request, unauthorizedUrl);
        }

        string username = values[0];
        string password = values[1];

        Identity user = request.signIn(username, password);
        if(user.isAuthenticated()) {
            return null;
        } else {
            return new RedirectResponse(request, unauthorizedUrl);
        }
    }
}
