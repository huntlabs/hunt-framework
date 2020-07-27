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

abstract class AuthMiddleware : AbstractMiddleware {

    this() {
        super();
    }

    this(RouteChecker routeChecker, MiddlewareEventHandler rejectionHandler) {
        super(routeChecker, rejectionHandler);
    }

    string guardName() {
        return _guardName;
    }

    void guardName(string value) {
        _guardName = value;
    }
    private string _guardName = DEFAULT_GURAD_NAME;

    protected AuthenticationToken getToken(Request request);

    protected Response onRejected(Request request) {
        if(_rejectionHandler !is null) {
            return _rejectionHandler(this, request);
        } else {
            if(request.isRestful()) {
                return new UnauthorizedResponse();
            } else {
                ApplicationConfig.AuthConf appConfig = app().config().auth;
                string unauthorizedUrl = appConfig.unauthorizedUrl;
                return new RedirectResponse(request, unauthorizedUrl);
            }            
        }
    } 

    Response onProcess(Request request, Response response = null) {
        version(HUNT_AUTH_DEBUG) infof("path: %s, method: %s", request.path(), request.method );

        bool needCheck = true;
        if(_routeChecker !is null) {
            needCheck = _routeChecker(request.path(), request.getMethod());
        }

        if(!needCheck) {
            return null;
        }

        version(HUNT_AUTH_DEBUG) infof("guard name: %s", guardName());

        Subject subject = SecurityUtils.getSubject(guardName());
        if(subject.isAuthenticated()) {
            version(HUNT_DEBUG) {
                Identity user = request.auth().user();
                string fullName = user.claimAs!(string)(ClaimTypes.FullName);
                infof("User [%s / %s] logged in.",  user.name(), fullName);
            }
            return null;
        }
        
        AuthenticationToken token = getToken(request);
            
        if(token !is null) {
            try {
                subject.login(token);
            } catch (AuthenticationException e) {
                version(HUNT_DEBUG) warning(e.msg);
                version(HUNT_AUTH_DEBUG) warning(e);
            } catch(Exception ex) {
                version(HUNT_DEBUG) warning(ex.msg);
                version(HUNT_AUTH_DEBUG) warning(ex);
            }

            if(subject.isAuthenticated()) {
                version(HUNT_DEBUG) {
                    Identity user = request.auth().user();
                    // Claim[] claims =  user.claims;
                    // foreach(Claim c; claims) {
                    //     tracef("%s, %s", c.type, c.value);
                    // }
                    string fullName = user.claimAs!(string)(ClaimTypes.FullName);
                    infof("User [%s / %s] logged in.",  user.name(), fullName);
                }
                return null;	
            }
        }
        
        return onRejected(request);
    }    
}