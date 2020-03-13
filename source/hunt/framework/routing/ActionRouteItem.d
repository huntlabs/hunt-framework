module hunt.framework.routing.ActionRouteItem;

import hunt.framework.routing.RouteItem;
import std.conv;

/**
 * 
 */
final class ActionRouteItem : RouteItem {

    // module
    string moduleName;

    // controller
    string controller;

    // action
    string action;

    string mca() {
        return (moduleName ? moduleName ~ "." : "") ~ controller ~ "." ~ action;
    }

    override string toString() {
        return "path: " ~ path ~ ", methods: " ~ methods.to!string() ~ ", mca: " ~ mca;
    }
}
