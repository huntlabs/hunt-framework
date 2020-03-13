module hunt.framework.routing.ResourceRouteItem;

import hunt.framework.routing.RouteItem;
import std.conv;

/**
 * 
 */
final class ResourceRouteItem : RouteItem {

    /// Is a folder for static content?
    bool canListing = false;

    string resourcePath;

    override string toString() {
        return "path: " ~ path ~ ", methods: " ~ methods.to!string()
            ~ ", resource path: " ~ resourcePath;
    }
}
