module hunt.framework.auth.Auth;

import hunt.framework.auth.Identity;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.JwtUtil;
import hunt.framework.auth.UserService;
import hunt.framework.http.Request;
import hunt.framework.provider.ServiceProvider;

import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;
import hunt.shiro.Exceptions;

import std.algorithm;
import std.array : split;
import std.base64;
import std.json;
import std.format;
import std.range;


/**
 * 
 */
class Auth {
    
    private Identity _user;
    private string _token;
    private AuthenticationScheme _scheme = AuthenticationScheme.None;
    private bool _remember = false;
    private bool _isTokenRefreshed = false;
    private bool _isLogout = false;

    private Request _request;

    this(Request request) {
        _request = request;
        _user = new Identity();


        // Detect the auth type automatically
        _token = _request.bearerToken();
        if(_token.empty()) {
            _token = _request.basicToken();
            if(!_token.empty()) {
                // _scheme = AuthenticationScheme.Basic;
                _user.authenticate(_token, AuthenticationScheme.Basic);
            }
        } else {
            _user.authenticate(_token, AuthenticationScheme.Bearer);
        }

        // Detect the token from cookie
        if(_token.empty()) {
            _token = request.cookie(BEARER_COOKIE_NAME);
            if(_token.empty()) {
                _token = request.cookie(BASIC_COOKIE_NAME);
                if(!_token.empty()) {
                _user.authenticate(_token, AuthenticationScheme.Basic);
                }
            } else {
                _user.authenticate(_token, AuthenticationScheme.Bearer);
            }
        }
        
        if(_user.isAuthenticated()) {
            _scheme = _user.authScheme();
        }
    }


    Identity user() {
        return _user;
    }

    Identity signIn(string name, string password, bool remember = false, 
            AuthenticationScheme scheme = AuthenticationScheme.Bearer) {
        _user.authenticate(name, password, remember);
        _remember = remember;
        _scheme = scheme;

        if(_user.isAuthenticated()) {
            if(scheme == AuthenticationScheme.Bearer) {
                UserService userService = serviceContainer().resolve!UserService();
                string salt = userService.getSalt(name, password);
                _token = JwtUtil.sign(name, salt);
            } else {
                string str = name ~ ":" ~ password;
                ubyte[] data = cast(ubyte[])str.dup;
                _token = cast(string)Base64.encode(data);
            }
        }

        return _user;
    }

    void signOut() {
        _token = null;
        _remember = false;
        _isLogout = true;
        
        if(_scheme != AuthenticationScheme.Basic || _scheme != AuthenticationScheme.Bearer) {
            warningf("Unsupported auth type: %s", _scheme);
        }

        if(_user.isAuthenticated()) {
            _user.logout();
        }
    }

    string refreshToken() {
        string username = _user.name();
        if(!_user.isAuthenticated()) {
            throw new AuthenticationException( format("Use is not authenticated: %s", _user.name()));
        }

        if(_scheme == AuthenticationScheme.Bearer) {
            UserService userService = serviceContainer().resolve!UserService();
            // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-07-17T11:10:18+08:00
            // 
            string salt = userService.getSalt(username, "no password");
            _token = JwtUtil.sign(username, salt);
        } 
        
        _isTokenRefreshed = true;
        return _token;
    }

    // the token value for the "remember me" session.
    string token() {
        return _token;
    }

    AuthenticationScheme scheme() {
        return _scheme;
    }

    bool canRememberMe() {
        return _remember;
    }

    bool isTokenRefreshed() {
        return _isTokenRefreshed;
    }

    bool isLogout() {
        return _isLogout;
    }


}