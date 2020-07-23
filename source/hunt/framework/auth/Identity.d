module hunt.framework.auth.Identity;

import hunt.framework.auth.Claim;
import hunt.framework.auth.ClaimTypes;
import hunt.framework.auth.JwtToken;
import hunt.framework.auth.principal;

import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;
import hunt.shiro;

import std.base64;
import std.string;
import std.variant;

/**
 * User Identity
 */
class Identity {
    private Subject _subject;

    this() {
        _subject = SecurityUtils.getSubject();
    }

    ulong id() {
        PrincipalCollection pCollection = _subject.getPrincipals();
        UserIdPrincipal principal = PrincipalCollectionHelper.oneByType!(UserIdPrincipal)(pCollection);

        if(principal is null) {
            return 0;
        } else {
            return principal.getUserId();
        }        
    }

    string name() {
        PrincipalCollection pCollection = _subject.getPrincipals();
        UsernamePrincipal principal = PrincipalCollectionHelper.oneByType!(UsernamePrincipal)(pCollection);

        if(principal is null) {
            return "";
        } else {
            return principal.getUsername();
        }
    }
    
    AuthenticationScheme authScheme() {
        Variant var = claim(ClaimTypes.AuthScheme);
        if(var == null) return AuthenticationScheme.None;
        return cast(AuthenticationScheme)var.get!string();
        // PrincipalCollection pCollection = _subject.getPrincipals();
        // AuthSchemePrincipal principal = PrincipalCollectionHelper.oneByType!(AuthSchemePrincipal)(pCollection);

        // if(principal is null) {
        //     return AuthenticationScheme.None;
        // } else {
        //     return principal.getAuthScheme();
        // }
    }

    Variant claim(string type) {
        PrincipalCollection pCollection = _subject.getPrincipals();
        foreach(Object p; pCollection) {
            Claim claim = cast(Claim)p;
            if(claim is null) continue;
            if(claim.type == type) return claim.value();
        }

        return Variant(null);
    }
    
    T claimAs(T)(string type) {
        Variant v = claim(type);
        if(v == null) {
            version(HUNT_DEBUG) warning("The claim is null");
            return T.init;
        }

        return v.get!T();
    }

    Claim[] claims() {
        Claim[] r;

        PrincipalCollection pCollection = _subject.getPrincipals();
        foreach(Object p; pCollection) {
            Claim claim = cast(Claim)p;
            if(claim is null) continue;
            r ~= claim;
        }

        return r;
    }

    void authenticate(string username, string password, bool remember = true) {

        version(HUNT_SHIRO_DEBUG) { 
            tracef("Checking the status at first: %s", _subject.isAuthenticated());
        }

        if (_subject.isAuthenticated()) {
            _subject.logout();
        }

        UsernamePasswordToken token = new UsernamePasswordToken(username, password);
        token.setRememberMe(remember);

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
        version(HUNT_DEBUG) {
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
            _subject.login(token);
        } catch (AuthenticationException e) {
            version(HUNT_DEBUG) warning(e.msg);
            version(HUNT_AUTH_DEBUG) warning(e);
        } catch(Exception ex) {
            version(HUNT_DEBUG) warning(ex.msg);
            version(HUNT_AUTH_DEBUG) warning(ex);
        }
    }

    bool isAuthenticated() {
        return _subject.isAuthenticated();
    }

    bool hasRole(string role) {
        return _subject.hasRole(role);
    }
    
    bool hasAllRoles(string[] roles...) {
        return _subject.hasAllRoles(roles);
    }

    bool isPermitted(string[] permissions...) {
        bool[] resultSet = _subject.isPermitted(permissions);
        foreach(bool r; resultSet ) {
            if(!r) return false;
        }

        return true;
    }

    void logout() {
        _subject.logout();
    }

    override string toString() {
        return name(); 
    }
}
