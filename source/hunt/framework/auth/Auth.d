module hunt.framework.auth.Auth;

import hunt.framework.auth.AuthOptions;
import hunt.framework.auth.Claim;
import hunt.framework.auth.ClaimTypes;
import hunt.framework.auth.Identity;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.JwtUtil;
import hunt.framework.auth.UserService;
import hunt.framework.http.Request;
import hunt.framework.Simplify;
// import hunt.framework.provider.ServiceProvider;

import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;
import hunt.shiro.Exceptions;
import hunt.shiro.authc.AuthenticationToken;
import hunt.util.TypeUtils;

import jwt.JwtRegisteredClaimNames;

import std.algorithm;
import std.array : split;
import std.base64;
import std.json;
import std.format;
import std.range;
import std.variant;
import core.time;

private enum AuthState {
    Auto,
    Token,
    SignIn,
    SignOut
}


/**
 * 
 */
class Auth {
    
    private Identity _user;
    private string _token;
    private bool _remember = false;
    private bool _isTokenRefreshed = false;
    private bool _isLogout = false;
    private AuthState _state = AuthState.Auto;
    // private string _tokenCookieName = BEARER_COOKIE_NAME;  
    // private AuthenticationScheme _scheme = AuthenticationScheme.None;
    // private string _guardName = DEFAULT_GURAD_NAME;
    private AuthOptions _options;

    private Request _request;
    
    this(Request request) {
        this(request, new AuthOptions());
    }

    this(Request request, AuthOptions options) {
        _request = request;
        _options = options;
        // _guardName = options.guardName;
        // _tokenCookieName = options.tokenCookieName;
        // _scheme = options.scheme;

        _user = new Identity(options.guardName);

        version(HUNT_AUTH_DEBUG) {
            warningf("path: %s, isAuthenticated: %s", request.path(), _user.isAuthenticated());
        }
    }

    // void tokenCookieName(string name) {
    //     _tokenCookieName = name;
    // }

    string tokenCookieName() {
        return _options.tokenCookieName;
    }

    private void autoDetect() {
        if(_state != AuthState.Auto) 
            return;

        version(HUNT_DEBUG) tracef("Detecting the authentication state from %s", tokenCookieName());
        AuthenticationScheme _scheme = _options.scheme;
        if(_scheme == AuthenticationScheme.None)
            _scheme = AuthenticationScheme.Bearer;

        // Detect the auth type automatically
        if(_scheme == AuthenticationScheme.Bearer) {
            _token = _request.bearerToken();
        } else if(_scheme == AuthenticationScheme.Basic) {
            _token = _request.basicToken();
        }

        if(_token.empty()) { // Detect the token from cookie
            _token = request.cookie(tokenCookieName());
        } 

        if(!_token.empty()) {
            _user.authenticate(_token, _scheme);
        }

        _state = AuthState.Token;
    }

    Identity user() {
        // autoDetect();
        return _user;
    }

    Identity signIn(string name, string password, string salt, bool remember = false) {
        _user.authenticate(name, password, remember);

        _remember = remember;
        string scheme = _options.scheme;
        _state = AuthState.SignIn;

        if(_user.isAuthenticated()) {
            if(scheme == AuthenticationScheme.Bearer) {
                // UserService userService = serviceContainer().resolve!UserService();

                // string salt = userService.getSalt(name, password);
                int exp = config().auth.tokenExpiration;

                JSONValue claims;
                claims["user_id"] = _user.id;

                Claim[] userClaims = _user.claims();

                foreach(Claim c; userClaims) {
                    string claimName = toJwtClaimName(c.type());
                    Variant value = c.value;
                    if(TypeUtils.isIntegral(value.type))
                        claims[claimName] = JSONValue(c.value.get!(long));
                    else if(TypeUtils.isUsignedIntegral(value.type))
                        claims[claimName] = JSONValue(c.value.get!(ulong));
                    else if(TypeUtils.isFloatingPoint(value.type))
                        claims[claimName] = JSONValue(c.value.get!(float));
                    else 
                        claims[claimName] = JSONValue(c.value.toString());
                }

                _token = JwtUtil.sign(name, salt, exp.seconds, claims);
            } else if(scheme == AuthenticationScheme.Basic) {
                string str = name ~ ":" ~ password;
                ubyte[] data = cast(ubyte[])str;
                _token = cast(string)Base64.encode(data);
            } else {
                error("Unsupported AuthenticationScheme: %s", scheme);
            }
        }

        return _user;
    }


    static string toJwtClaimName(string name) {
        switch(name) {
            case  ClaimTypes.Name: 
                return JwtRegisteredClaimNames.Sub;

            case  ClaimTypes.Nickname: 
                return JwtRegisteredClaimNames.Nickname;

            case  ClaimTypes.GivenName: 
                return JwtRegisteredClaimNames.GivenName;

            case  ClaimTypes.Surname: 
                return JwtRegisteredClaimNames.FamilyName;

            case  ClaimTypes.Email: 
                return JwtRegisteredClaimNames.Email;

            case  ClaimTypes.Gender: 
                return JwtRegisteredClaimNames.Gender;

            case  ClaimTypes.DateOfBirth: 
                return JwtRegisteredClaimNames.Birthdate;
            
            default:
                return name;
        }
    }

    void signOut() {
        _state = AuthState.SignOut;
        _token = null;
        _remember = false;
        _isLogout = true;
        
        if(_options.scheme != AuthenticationScheme.Basic && _options.scheme != AuthenticationScheme.Bearer) {
            warningf("Unsupported auth type: %s", _options.scheme);
        }

        if(_user.isAuthenticated()) {
            _user.logout();
        }
    }

    string refreshToken(string salt) {
        string username = _user.name();
        if(!_user.isAuthenticated()) {
            throw new AuthenticationException( format("The use is not authenticated: %s", _user.name()));
        }

        if(_options.scheme == AuthenticationScheme.Bearer) {
            // UserService userService = serviceContainer().resolve!UserService();
            // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-07-17T11:10:18+08:00
            // 
            // string salt = userService.getSalt(username, "no password");
            _token = JwtUtil.sign(username, salt);
        } 
        
        _state = AuthState.Token;
        _isTokenRefreshed = true;
        return _token;
    }

    // the token value for the "remember me" session.
    string token() {
        autoDetect();
        return _token;
    }
  
    AuthenticationScheme scheme() {
        autoDetect();
        return _options.scheme;
    }

    // void scheme(AuthenticationScheme value) {
    //     _scheme = value;
    // }

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