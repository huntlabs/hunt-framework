module hunt.framework.routing.RouteItem;

import hunt.framework.middleware.MiddlewareInterface;
import hunt.logging.ConsoleLogger;

/**
 * 
 */
class RouteItem {
    private TypeInfo_Class[] _allowedMiddlewares;
    private TypeInfo_Class[] _skippedMiddlewares;

    string[] methods;

    string path;
    string urlTemplate;
    string pattern;
    string[int] paramKeys;

    bool isRegex = false;

    void withMiddleware(T)() if(is(T : MiddlewareInterface)) {
        _allowedMiddlewares ~= T.classinfo;
    }

    void withMiddleware(string name) {
        try {
            TypeInfo_Class typeInfo = MiddlewareInterface.get(name);
            _allowedMiddlewares ~= typeInfo;
        } catch(Exception ex) {
            warning(ex.msg);
        }
    }

    TypeInfo_Class[] allowedMiddlewares() {
        return _allowedMiddlewares;
    }

    void withoutMiddleware(T)() if(is(T : MiddlewareInterface)) {
        _skippedMiddlewares ~= T.classinfo;
    }

    void withoutMiddleware(string name) {
        try {
            TypeInfo_Class typeInfo = MiddlewareInterface.get(name);
            _skippedMiddlewares ~= typeInfo;
        } catch(Exception ex) {
            warning(ex.msg);
        }
    }

    TypeInfo_Class[] skippedMiddlewares() {
        return _skippedMiddlewares;
    }


}
