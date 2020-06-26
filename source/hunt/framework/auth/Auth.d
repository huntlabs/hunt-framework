module hunt.framework.auth.Auth;


import hunt.framework.auth.Identity;
import hunt.framework.auth.JwtUtil;
import hunt.framework.auth.UserService;
import hunt.framework.http.Request;
import hunt.framework.provider.ServiceProvider;

import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;

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
    private bool _isLogout = false;

    private Request _request;

    this(Request request) {
        _request = request;
        _user = new Identity();
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

    void signOut(AuthenticationScheme scheme = AuthenticationScheme.None) {
        _token = null;
        _remember = false;
        _isLogout = true;

        if(scheme == AuthenticationScheme.None) {
            // Detect the auth type automatically
            string token = _request.bearerToken();
            if(token.empty()) {
                token = _request.basicToken();
                if(!token.empty()) {
                    _scheme = AuthenticationScheme.Basic;
                }
            } else {
                _scheme = AuthenticationScheme.Bearer;
            }
        }

        if(_scheme != AuthenticationScheme.Basic || _scheme != AuthenticationScheme.Bearer) {
            warningf("Unsupported auth type: %s", _scheme);
        }

        if(_user.isAuthenticated()) {
            _user.logout();
        }
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

    bool isLogout() {
        return _isLogout;
    }


}