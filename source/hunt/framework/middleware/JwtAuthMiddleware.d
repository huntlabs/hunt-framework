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

import std.range;
import std.string;


/**
 * 
 */
class JwtAuthMiddleware : MiddlewareInterface {
    enum TokenHeader = "Bearer ";

    string name() {
        return typeof(this).stringof;
    }


    Response onProcess(Request request, Response response = null) {

        version(HUNT_SHIRO_DEBUG) infof("path: %s, method: %s", request.path(), request.method );
        // if(request.path().startsWith("/admincp/login") ) { // && request.method == HttpMethod.GET
        //     return null;
        // }

        Subject subject = SecurityUtils.getSubject();
        if(subject.isAuthenticated()) {
            return null;
        }
        
        string tokenString = request.header(HttpHeader.AUTHORIZATION);

        ApplicationConfig.AuthConf appConfig = app().config().auth;
        string unauthorizedUrl = appConfig.unauthorizedUrl;

        unauthorizedUrl = "/403.html";

        
        if(!tokenString.empty) {
            if(!tokenString.startsWith(TokenHeader)) {
                return new RedirectResponse(request, unauthorizedUrl);
            }

            tokenString = tokenString[TokenHeader.length .. $];
        }

        if(tokenString.empty)
            tokenString = request.cookie("__auth_token__");
            
        // info(tokenString);

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
                return null;	
            }
        }

        return new RedirectResponse(request, unauthorizedUrl);        
    }
}