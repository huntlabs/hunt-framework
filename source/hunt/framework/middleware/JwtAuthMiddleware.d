module hunt.framework.middleware.JwtAuthMiddleware;

import hunt.framework.middleware.MiddlewareInterface;

import hunt.framework.application.Application;
import hunt.framework.auth.JwtToken;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.http.RedirectResponse;
import hunt.framework.http.Request;
import hunt.framework.http.Response;
// import hunt.framework.provider.ServiceProvider;
import hunt.framework.Simplify;

import hunt.http.HttpHeader;
import hunt.logging.ConsoleLogger;
import hunt.shiro;
import hunt.Functions;

import std.range;
import std.string;

alias RouteCheckingHandler = Func1!(string, bool);

/**
 * 
 */
class JwtAuthMiddleware : MiddlewareInterface {
    enum TokenHeader = "Bearer ";

    private RouteCheckingHandler _checkingHandler;

    this(RouteCheckingHandler handler) {
        _checkingHandler = handler;
    }

    string name() {
        return typeof(this).stringof;
    }


    Response onProcess(Request request, Response response = null) {

        version(HUNT_SHIRO_DEBUG) infof("path: %s, method: %s", request.path(), request.method );
        // if(request.path().startsWith("/admincp/login") ) { // && request.method == HttpMethod.GET
        //     return null;
        // }

        bool needCheck = true;
        if(_checkingHandler !is null) {
            needCheck = _checkingHandler(request.path());
        }

        if(!needCheck) {
            return null;
        }

        Subject subject = SecurityUtils.getSubject();
        if(subject.isAuthenticated()) {
            warningf("User %s has logged in.", request.user.name());
            return null;
        }
        
        string tokenString = request.header(HttpHeader.AUTHORIZATION);

        ApplicationConfig.AuthConf appConfig = app().config().auth;
        string unauthorizedUrl = appConfig.unauthorizedUrl;
        
        if(!tokenString.empty) {
            if(!tokenString.startsWith(TokenHeader)) {
                return new RedirectResponse(request, unauthorizedUrl);
            }

            tokenString = tokenString[TokenHeader.length .. $];
        }

        if(tokenString.empty)
            tokenString = request.cookie("__auth_token__");

        if(!tokenString.empty) {
            try {
                JwtToken token = new JwtToken(tokenString);
                subject.login(token);
            } catch (AuthenticationException e) {
                version(HUNT_DEBUG) warning(e.msg);
                version(HUNT_SHRO_DEBUG) warning(e);
            } catch(Exception ex) {
                version(HUNT_DEBUG) warning(ex.msg);
                version(HUNT_SHRO_DEBUG) warning(ex);
            }

            if(subject.isAuthenticated()) {
                warningf("User %s logged in.", request.user.name());
                return null;	
            }
        }

        return new RedirectResponse(request, unauthorizedUrl);        
    }
}