module hunt.framework.auth.AuthService;

import hunt.framework.auth.Guard;

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
        if(itemPtr is null)
            throw new Exception("No guard found: " ~ name);
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