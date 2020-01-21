module hunt.framework.application.RouteConfig;

import hunt.logging.ConsoleLogger;

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.range;
import std.regex;
import std.string;


/**
 * 
 */
class RouteItem {
    string[] methods;

    string path;
    string urlTemplate;
    string pattern;
    string[int] paramKeys;

    bool isRegex = false;

}

/**
 * 
 */
final class ActionRouteItem : RouteItem {

    // hunt module
    string moduleName;

    // hunt controller
    string controller;

    // hunt action
    string action;

    string mca() {
        return (moduleName ? moduleName ~ "." : "") ~ controller ~ "." ~ action;
    }

    override string toString() {
        return "path: " ~ path ~ ", methods: " ~ methods.to!string() ~ ", mca: " ~ mca;
    }
}

/**
 * 
 */
final class ResourceRouteItem : RouteItem {

    /// Is a folder for static content?
    bool canListing = false;

    string resourcePath;

    override string toString() {
        return "path: " ~ path ~ ", methods: " ~ methods.to!string() ~ ", resource path: " ~ resourcePath;
    }
}

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

alias RouteGroupHandler = void delegate(RouteGroup group, RouteItem[] routes);
alias RouteParsingHandler = void delegate(RouteItem route);

/** 
 * 
 */
struct RouteConfig {

    __gshared RouteItem[][string] allRouteItems;
    __gshared RouteGroup[] allRouteGroups;

    static ActionRouteItem getRoute(string group, string mca) {
        auto itemPtr = group in allRouteItems;
        if(itemPtr is null)
            return null;
        
        foreach(RouteItem item; *itemPtr) {
            ActionRouteItem actionItem = cast(ActionRouteItem)item;
            if(actionItem is null) continue;
            if(actionItem.mca ==  mca) return actionItem;
        }

        return null;
    }

    static RouteGroup getRouteGroupe(string name) {
        auto item = allRouteGroups.find!(g => g.name == name).takeOne;
        if(item.empty)
            return null;
        return item.front;
    }

    static RouteItem[] load(string filename) {
        import std.stdio;

        RouteItem[] items;

        auto f = File(filename);

        scope (exit) {
            f.close();
        }

        foreach (line; f.byLineCopy) {
            RouteItem item = parseOne(cast(string)line);
            if(item is null)
                continue;

            if (item.path.length > 0) {
                items ~= item;
            }
        }

        return items;
    }

    static RouteItem parseOne(string line) {
        line = strip(line);

        // not availabale line return null
        if (line.length == 0 || line[0] == '#') {
            return null;
        }


        // match example: 
        // GET, POST    /users    module.controller.action | staticDir:wwwroot
        auto matched = line.match(
                regex(`([^/]+)\s+(/[\S]*?)\s+((staticDir[\:][\w|\/|\\]+)|([\w\.]+))`));

        if (!matched) {
            if(!line.empty()) {
                warningf("Unmatched line: %s", line);
            }
            return null;
        }

        //
        RouteItem item;
        string part3 = matched.captures[3].to!string.strip;
        
        // 
        if (part3.startsWith("staticDir:")) {
            ResourceRouteItem routeItem = new ResourceRouteItem();
            routeItem.resourcePath = part3.chompPrefix("staticDir:");
            item = routeItem;
        } else {
            ActionRouteItem routeItem = new ActionRouteItem();
            // mca
            string mca = part3;
            string[] mcaArray = split(mca, ".");

            if (mcaArray.length > 3 || mcaArray.length < 2) {
                logWarningf("this route config mca length is: %d (%s)", mcaArray.length, mca);
                return null;
            }

            if (mcaArray.length == 2) {
                routeItem.controller = mcaArray[0];
                routeItem.action = mcaArray[1];
            }
            else {
                routeItem.action = mcaArray[0];
                routeItem.controller = mcaArray[1];
                routeItem.action = mcaArray[2];
            }
            item = routeItem;
        }
        
        // methods
        string methods = matched.captures[1].to!string.strip;
        methods = methods.toUpper();
        
        if(methods.length > 2) {
            if(methods[0] == '[' && methods[$-1] == ']')
                methods = methods[1..$-2];
        }
        
        if(methods == "*" || methods == "ALL" ) {
            item.methods = null;
        } else {
            item.methods = split(methods, ",");
        }

        // path
        string path = matched.captures[2].to!string.strip;
        item.path = path;

        // regex path
        auto matches = path.matchAll(regex(`\{(\w+)(<([^>]+)>)?\}`));
        if (matches) {
            string[int] paramKeys;
            int paramCount = 0;
            string pattern = path;
            string urlTemplate = path;

            foreach (m; matches) {
                paramKeys[paramCount] = m[1];
                string reg = m[3].length ? m[3] : "\\w+";
                pattern = pattern.replaceFirst(m[0], "(" ~ reg ~ ")");
                urlTemplate = urlTemplate.replaceFirst(m[0], "{" ~ m[1] ~ "}");
                paramCount++;
            }

            item.isRegex = true;
            item.pattern = pattern;
            item.paramKeys = paramKeys;
            item.urlTemplate = urlTemplate;
        }

        return item;
    }
}


/**
 * 
 */
string makeRouteHandlerKey(ActionRouteItem route, RouteGroup group = null) {
    string moduleName = route.moduleName;
    string controller = route.controller;

    string key = format("app.%scontroller.%s%s.%scontroller.%s", 
        moduleName.empty() ? "" : moduleName ~ ".",
        group is null ? "" : group.name ~ ".",
        controller, 
        controller, route.action);
    return key.toLower();
}