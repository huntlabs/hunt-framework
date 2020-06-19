module hunt.framework.auth.AuthUser;

import hunt.framework.auth.AuthRole;

import hunt.shiro;
import hunt.logging.ConsoleLogger;

/**
 * 
 */
class AuthUser {
    private Subject _subject;

    this() {
        _subject = SecurityUtils.getSubject();
    }

    ulong id;

    string name;

    string password;

    string fullName;

    AuthRole[] roles;

    // string[] permissions;

    void authenticate(string username, string password) {
        this.name = username;
        this.password = password;

        warningf("Checking at first: %s", _subject.isAuthenticated());

        if (_subject.isAuthenticated()) {
            _subject.logout();
        }

        UsernamePasswordToken token = new UsernamePasswordToken(username, password);
        token.setRememberMe(true);

        try {
            _subject.login(token);
        } catch (UnknownAccountException uae) {
            info("There is no user with username of " ~ token.getPrincipal());
        } catch (IncorrectCredentialsException ice) {
            info("Password for account " ~ token.getPrincipal() ~ " was incorrect!");
        } catch (LockedAccountException lae) {
            info("The account for username " ~ token.getPrincipal()
                    ~ " is locked.  " ~ "Please contact your administrator to unlock it.");
        } catch (AuthenticationException ex) {
            errorf("Authentication failed: ", ex.msg);
            error(ex);
        } catch (Exception ex) {
            errorf("Authentication failed: ", ex.msg);
            error(ex);
        }
    }

    bool isAuthenticated() {
        return _subject.isAuthenticated();
    }

    bool hasRole(string role) {
        return _subject.hasRole(role);
    }

    override string toString() {
        return "name: " ~ name ~ ", FullName: " ~ fullName;
    }
}
