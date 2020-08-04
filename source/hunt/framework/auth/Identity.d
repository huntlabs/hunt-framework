module hunt.framework.auth.Identity;

import hunt.framework.auth.UserDetails;
import hunt.framework.auth.Claim;
import hunt.framework.auth.ClaimTypes;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.principal;
import hunt.framework.config.AuthUserConfig;

import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;
import hunt.shiro;

import std.algorithm;
import std.array;
import std.base64;
import std.string;
import std.variant;

/**
 * User Identity
 */
class Identity {
    private Subject _subject;
    private string _guardName;

    this(string guardName) {
        _guardName = guardName;
    }

    Subject subject() {
        if(_subject is null) {
            _subject = SecurityUtils.getSubject(_guardName);
        }
        return _subject;
    }

    ulong id() {
        UserDetails userDetails = cast(UserDetails)subject().getPrincipal();
        if(userDetails !is null) {
            return userDetails.id;
        }
        return 0;       
    }

    string name() {
        UserDetails userDetails = cast(UserDetails)subject().getPrincipal();
        if(userDetails !is null) {
            return userDetails.name;
        }
        return "";
    }
    
    AuthenticationScheme authScheme() {
        Variant var = claim(ClaimTypes.AuthScheme);
        if(var == null) return AuthenticationScheme.None;
        return cast(AuthenticationScheme)var.get!string();
    }

    string fullName() {
        return claimAs!(string)(ClaimTypes.FullName);
    }

    Variant claim(string type) {
        Variant v = Variant(null);
        UserDetails userDetails = cast(UserDetails)subject().getPrincipal();
        if(userDetails !is null) {
            v = userDetails.claim(type);
        }

        return v;
    }
    
    T claimAs(T)(string type) {
        Variant v = claim(type);
        if(v == null || !v.hasValue()) {
            return T.init;
        }

        return v.get!T();
    }

    Claim[] claims() {
        Claim[] r;
        
        UserDetails userDetails = cast(UserDetails)subject().getPrincipal();
        if(userDetails !is null) {
            r = userDetails.claims();
        }

        return r;
    }

    void authenticate(string username, string password, bool remember = true, 
            string tokenName = DEFAULT_AUTH_TOKEN_NAME) {
        Subject _subject = subject();
        version(HUNT_AUTH_DEBUG) { 
            tracef("Checking the status at first: %s", _subject.isAuthenticated());
        }

        if (_subject.isAuthenticated()) {
            _subject.logout();
        }

        UsernamePasswordToken token = new UsernamePasswordToken(username, password);
        token.setRememberMe(remember);
        token.name = tokenName;

        try {
            _subject.login(token);
        } catch (UnknownAccountException ex) {
            info("There is no user with username of " ~ token.getPrincipal());
        } catch (IncorrectCredentialsException ex) {
            info("Password for account " ~ token.getPrincipal() ~ " was incorrect!");
        } catch (LockedAccountException ex) {
            info("The account for username " ~ token.getPrincipal()
                    ~ " is locked.  " ~ "Please contact your administrator to unlock it.");
        } catch (AuthenticationException ex) {
            errorf("Authentication failed: ", ex.msg);
            version(HUNT_DEBUG) error(ex);
        } catch (Exception ex) {
            errorf("Authentication failed: ", ex.msg);
            version(HUNT_DEBUG) error(ex);
        }
    }

    void authenticate(string token, AuthenticationScheme scheme) {
        version(HUNT_AUTH_DEBUG) {
            infof("scheme: %s", scheme);
        }

        if(scheme == AuthenticationScheme.Bearer) {
            bearerLogin(token);
        } else if(scheme == AuthenticationScheme.Basic) {
            basicLogin(token);
        } else {
            warningf("Unknown AuthenticationScheme: %s", scheme);
        }
    }


    private void basicLogin(string tokenString) {
        ubyte[] decoded = Base64.decode(tokenString);
        string[] values = split(cast(string)decoded, ":");
        if(values.length != 2) {
            warningf("Wrong token: %s", values);
            return;
        }

        string username = values[0];
        string password = values[1];
        authenticate(username, password, true);
    }

    private void bearerLogin(string tokenString) {
        try {
            JwtToken token = new JwtToken(tokenString);
            subject().login(token);
        } catch (AuthenticationException e) {
            warning(e.msg);
            version(HUNT_AUTH_DEBUG) warning(e);
        } catch(Exception ex) {
            warning(ex.msg);
            version(HUNT_DEBUG) warning(ex);
        }
    }

    bool login(AuthenticationToken token) {
        Subject sj = subject();
        version(HUNT_AUTH_DEBUG) { 
            tracef("Checking the status at first: %s", _subject.isAuthenticated());
        }

        if (sj.isAuthenticated()) {
            sj.logout();
        }        
        sj.logout();

        if(token is null) {
            warning("The token is null");
            return false;
        }


        try {
            // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-08-01T16:13:55+08:00
            // Session with id [b82d265a-ec96-406b-854c-0a846e690aff] has expired
            sj.login(token);
        } catch (AuthenticationException e) {
            version(HUNT_DEBUG) warning(e.msg);
            version(HUNT_AUTH_DEBUG) warning(e);
        } catch(Exception ex) {
            version(HUNT_DEBUG) warning(ex.msg);
            version(HUNT_AUTH_DEBUG) warning(ex);
        }

        return sj.isAuthenticated();
    }

    bool isAuthenticated() {
        return subject().isAuthenticated();
    }

    bool hasRole(string role) {
        return subject().hasRole(role);
    }
    
    bool hasAllRoles(string[] roles...) {
        return subject().hasAllRoles(roles);
    }

    bool isPermitted(string[] permissions...) {
        
        // Try to convert all the custom permissions to shiro's ones
        try {
            string[] shiroPermissions = permissions.map!(p => p.strip().toShiroPermissions()).array;
            bool[] resultSet = subject().isPermitted(shiroPermissions);
            foreach(bool r; resultSet ) {
                if(!r) return false;
            }
        } catch(Exception ex) {
            warning(ex.msg);
            version(HUNT_DEBUG) warning(ex);
            return false;
        }

        return true;
    }

    void touchSession() {
        Session session = subject().getSession(false);
        if (session !is null) {
            try {
                session.touch();
            } catch (Throwable t) {
                error("session.touch() method invocation has failed.  Unable to update " ~
                        "the corresponding session's last access time based on the incoming request.");
                error(t.msg);
                version(HUNT_AUTH_DEBUG) warning(t);
            }
        }
    }

    void logout() {
        subject().logout();
    }

    override string toString() {
        return name(); 
    }
}
