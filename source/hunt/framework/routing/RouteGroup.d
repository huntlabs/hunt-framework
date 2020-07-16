module hunt.framework.routing.RouteGroup;

import hunt.framework.routing.ActionRouteItem;
import hunt.framework.routing.RouteItem;
import hunt.framework.middleware.MiddlewareInterface;

/**
 * 
 */
final class RouteGroup {

    private RouteItem[] _allItems;

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
            if (actionItem.mca == actionId)
                return actionItem;
        }

        return null;
    }

    override string toString() {
        return "{" ~ name ~ ", " ~ type ~ ", " ~ value ~ "}";
    }

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
