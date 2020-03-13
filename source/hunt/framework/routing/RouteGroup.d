module hunt.framework.routing.RouteGroup;


/**
 * 
 */
final class RouteGroup {

    // type
    enum string DEFAULT = "default";
    enum string HOST = "host";
    enum string PATH = "path";

    string name;
    string type;
    string value;

    override string toString() {
        return "{" ~ name ~ ", " ~ type ~ ", " ~ value ~ "}";
    }
}
