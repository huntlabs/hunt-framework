module hunt.framework.application.RouteConfig;

import hunt.logging.ConsoleLogger;

import std.array;
import std.conv;
import std.file;
import std.range;
import std.regex;
import std.string;


/**
 * 
 */
final class RouteItem {

    string[] methods;

    string path;

    bool isRegex = false;

    // hunt module
    string moduleName;

    // hunt controller
    string controller;

    // hunt action
    string action;

    override string toString() {
        return "path: " ~ path ~ ", methods: " ~ methods.to!string() ~ ", mca: " ~ makeRouteHandlerKey(this);
    }
}

/**
 * 
 */
final class RouteGroupInfo {
    string name;
    string type;
    string value;

    override string toString() {
        return "{" ~ name ~ ", " ~ type ~ ", " ~ value ~ "}";
    }
}

enum RouteGroupType {
    Host,
    Path
}

alias RouteGroupHandler = void delegate(RouteGroupInfo group, RouteItem[] routes);

alias RouteParsingHandler = void delegate(RouteItem route);

/** 
 * 
 */
struct RouteConfig {
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
        // GET, POST    /users    module.controller.action | staticDir:public
        auto matched = line.match(
                regex(`([^/]+)\s+(/[\S]*?)\s+((staticDir[\:][\w|\/|\\]+)|([\w\.]+))`));

        if (!matched) {
            if(!line.empty()) {
                warningf("Unmatched line: %s", line);
            }
            return null;
        }

        RouteItem item = new RouteItem();

        // path
        item.path = matched.captures[2].to!string.strip;

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

        // mca
        string mca = matched.captures[3].to!string.strip;

        string[] mcaArray = split(mca, ".");

        if (mcaArray.length > 3 || mcaArray.length < 2) {
            logWarningf("this route config mca length is: %d (%s)", mcaArray.length, mca);
            return null;
        }

        if (mcaArray.length == 2) {
            item.controller = mcaArray[0];
            item.action = mcaArray[1];
        }
        else {
            item.action = mcaArray[0];
            item.controller = mcaArray[1];
            item.action = mcaArray[2];
        }

        return item;
    }
}



string makeRouteHandlerKey(RouteItem route, RouteGroupInfo group = null) {
    string moduleName = route.moduleName;
    string controller = route.controller;

    string key = format("app.%scontroller.%s%s.%scontroller.%s", 
        moduleName.empty() ? "" : moduleName ~ ".",
        group is null ? "" : group.name ~ ".",
        controller, 
        controller, route.action);

    // if (route.staticFilePath == string.init) {
    // if (route.moduleName is null) {
    //     handleKey = "app.controller." ~ ((route.getGroup() == DEFAULT_ROUTE_GROUP)
    //             ? "" : route.getGroup() ~ ".") ~ route.getController() ~ "." ~ route.getController()
    //         ~ "controller." ~ route.getAction();
    // }
    // else {
    //     handleKey = "app." ~ route.moduleName ~ ".controller." ~ ((route.getGroup() == DEFAULT_ROUTE_GROUP)
    //             ? "" : route.getGroup() ~ ".") ~ route.getController() ~ "." ~ route.getController()
    //         ~ "controller." ~ route.getAction();

    //     // if (getRouteHandler(handleKey) is null) {
    //     //     handleKey = "app.component." ~ route.moduleName ~ ".controller." ~ (
    //     //             (route.getGroup() == DEFAULT_ROUTE_GROUP) ? "" : route.getGroup() ~ ".")
    //     //         ~ route.getController() ~ "." ~ route.getController() ~ "controller." ~ route.getAction();
    //     // }
    // }
    // }
    // else {
    //     handleKey = "hunt.application.staticfile.StaticfileController.doStaticFile";
    // }

    return key.toLower();
}