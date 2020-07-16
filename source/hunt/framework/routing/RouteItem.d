module hunt.framework.routing.RouteItem;

import hunt.framework.middleware.MiddlewareInterface;

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

    void withMiddleware(T)() if(is(T : AbstractMiddleware)) {
        _allowedMiddlewares ~= T.classinfo;
    }

    TypeInfo_Class[] allowedMiddlewares() {
        return _allowedMiddlewares;
    }

    void withoutMiddleware(T)() if(is(T : AbstractMiddleware)) {
        _skippedMiddlewares ~= T.classinfo;
    }

    TypeInfo_Class[] skippedMiddlewares() {
        return _skippedMiddlewares;
    }

}
