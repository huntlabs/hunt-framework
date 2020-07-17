module hunt.framework.auth.Identity;

import hunt.framework.auth.principal;

import hunt.http.AuthenticationScheme;
import hunt.logging.ConsoleLogger;
import hunt.shiro;

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
        PrincipalCollection pCollection = _subject.getPrincipals();
        AuthSchemePrincipal principal = PrincipalCollectionHelper.oneByType!(AuthSchemePrincipal)(pCollection);

        if(principal is null) {
            return AuthenticationScheme.None;
        } else {
            return principal.getAuthScheme();
        }
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
