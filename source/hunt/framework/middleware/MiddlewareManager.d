module hunt.framework.middleware.MiddlewareManager;

import hunt.framework.middleware.MiddlewareInterface;
import hunt.logging.ConsoleLogger;

import std.exception;
import std.format;

/**
 * 
 */
struct MiddlewareManager {
    private __gshared TypeInfo_Class[string] _all;

    static void register(T)() if(is(T : AbstractMiddleware)) {
        string simpleName = T.stringof;
        auto itemPtr = simpleName in _all;
        if(itemPtr !is null) {
            warning("The middleware [%s] will be overwritten by [%s]", 
                itemPtr.name(), T.classinfo.name());
        }

        _all[simpleName] = T.classinfo;
    }

    /**
     * Simple name
     */
    TypeInfo_Class get(string name) {
        auto itemPtr = name in _all;
        if(itemPtr is null) {
            throw new Exception(format("The middleware %s has not been registered", name));
        }

        return *itemPtr;
    }
}