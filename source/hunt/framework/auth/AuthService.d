module hunt.framework.auth.AuthService;

import hunt.framework.auth.guard;

import hunt.logging.ConsoleLogger;

/**
 * 
 */
class AuthService {

    private Guard[string] _guards;

    void addGuard(Guard guard) {
        string name = guard.name();
        _guards[name] = guard;
    }

    Guard guard(string name) {
        auto itemPtr = name in _guards;
        if(itemPtr is null) {
            version(HUNT_AUTH_DEBUG) warning("No guard found: " ~ name);
            return null;
        }
        return *itemPtr;
    }

    Guard[] guards() {
        return _guards.values;
    }

    void boot() {

        foreach(string key, Guard g; _guards) {
            g.boot();
        }

    }
}