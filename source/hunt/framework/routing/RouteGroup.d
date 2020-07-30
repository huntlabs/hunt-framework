module hunt.framework.routing.RouteGroup;

import hunt.framework.routing.ActionRouteItem;
import hunt.framework.routing.RouteItem;
import hunt.framework.auth.AuthOptions;
import hunt.framework.middleware.MiddlewareInterface;

import hunt.logging.ConsoleLogger;

/**
 * 
 */
final class RouteGroup {

    private RouteItem[] _allItems;
    private string _guardName = DEFAULT_GURAD_NAME;

    private TypeInfo_Class[] _allowedMiddlewares;
    private TypeInfo_Class[] _skippedMiddlewares;

    // type
    enum string DEFAULT = "default";
    enum string HOST = "host";
    enum string DOMAIN = "domain";
    enum string PATH = "path";

    string name;
    string type;
    string value;


    void appendRoutes(RouteItem[] items) {
        _allItems ~= items;
    }

    RouteItem get(string actionId) {
        foreach (RouteItem item; _allItems) {
            ActionRouteItem actionItem = cast(ActionRouteItem) item;
            if (actionItem is null)
                continue;
            if (actionItem.actionId == actionId)
                return actionItem;
        }

        return null;
    }

    override string toString() {
        return "{" ~ name ~ ", " ~ type ~ ", " ~ value ~ "}";
    }

    string guardName() {
        return _guardName;
    }

    RouteGroup guardName(string value) {
        _guardName = value;
        return this;
    }

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
