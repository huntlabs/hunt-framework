module hunt.framework.routing.RouteConfigManager;

import hunt.framework.routing.ActionRouteItem;
import hunt.framework.routing.RouteItem;
import hunt.framework.routing.ResourceRouteItem;
import hunt.framework.routing.RouteGroup;

import hunt.framework.config.ApplicationConfig;
import hunt.framework.Init;
import hunt.logging.ConsoleLogger;
import hunt.http.routing.RouterManager;

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.path;
import std.range;
import std.regex;
import std.string;


/** 
 * 
 */
class RouteConfigManager {

    private ApplicationConfig _appConfig;
    private RouteItem[][string] _allRouteItems;
    private RouteGroup[] _allRouteGroups;
    private string _basePath;

    this(ApplicationConfig appConfig) {
        _appConfig = appConfig;
        _basePath = DEFAULT_CONFIG_PATH;
        loadGroupRoutes();
        loadDefaultRoutes();
    }

    string basePath() {
        return _basePath;
    }

    RouteConfigManager basePath(string value) {
        _basePath = value;
        return this;
    }

    private void addGroupRoute(RouteGroup group, RouteItem[] routes) {
        _allRouteItems[group.name] = routes;
        group.appendRoutes(routes);
        _allRouteGroups ~= group;

        RouteGroupType groupType = RouteGroupType.Host;
        if (group.type == "path") {
            groupType = RouteGroupType.Path;
        }
    }

    RouteItem get(string actionId) {
        return getRoute(RouteGroup.DEFAULT, actionId);
    }

    RouteItem get(string group, string actionId) {
        return getRoute(group, actionId);
    }

    RouteItem[][RouteGroup] allRoutes() {
        RouteItem[][RouteGroup] r;
        foreach (string key, RouteItem[] value; _allRouteItems) {
            foreach (RouteGroup g; _allRouteGroups) {
                if (g.name == key) {
                    r[g] ~= value;
                    break;
                }
            }
        }
        return r;
    }

    ActionRouteItem getRoute(string group, string actionId) {
        auto itemPtr = group in _allRouteItems;
        if (itemPtr is null)
            return null;

        foreach (RouteItem item; *itemPtr) {
            ActionRouteItem actionItem = cast(ActionRouteItem) item;
            if (actionItem is null)
                continue;
            if (actionItem.actionId == actionId)
                return actionItem;
        }

        return null;
    }

    ActionRouteItem getRoute(string groupName, string method, string path) {
        version(HUNT_FM_DEBUG) {
            tracef("matching: groupName=%s, method=%s, path=%s", groupName, method, path);
        }

        if(path.empty) {
            warning("path is empty");
            return null;
        }

        if(path != "/")
            path = path.stripRight("/");

        //
        // auto itemPtr = group.name in _allRouteItems;
        auto itemPtr = groupName in _allRouteItems;
        if (itemPtr is null)
            return null;

        foreach (RouteItem item; *itemPtr) {
            ActionRouteItem actionItem = cast(ActionRouteItem) item;
            if (actionItem is null)
                continue;

            // TODO: Tasks pending completion -@zhangxueping at 2020-03-13T16:23:18+08:00
            // handle /user/{id<[0-9]+>} 
            if(actionItem.path != path) continue;
            // tracef("actionItem: %s", actionItem);
            string[] methods = actionItem.methods;
            if (!methods.empty && !methods.canFind(method))
                continue;

            return actionItem;
        }

        return null;
    }

    RouteGroup group(string name = RouteGroup.DEFAULT) {
        auto item = _allRouteGroups.find!(g => g.name == name).takeOne;
        if (item.empty) {
            errorf("Can't find the route group: %s", name);
            return null;
        }
        return item.front;
    }

    private void loadGroupRoutes() {
        if (_appConfig.route.groups.empty)
            return;

        version (HUNT_DEBUG)
            info(_appConfig.route.groups);

        string[] groupConfig;
        foreach (v; split(_appConfig.route.groups, ',')) {
            groupConfig = split(v, ":");

            if (groupConfig.length != 3 && groupConfig.length != 4) {
                logWarningf("Group config format error ( %s ).", v);
            } else {
                string value = groupConfig[2];
                if (groupConfig.length == 4) {
                    if (std.conv.to!int(groupConfig[3]) > 0) {
                        value ~= ":" ~ groupConfig[3];
                    }
                }

                RouteGroup groupInfo = new RouteGroup();
                groupInfo.name = strip(groupConfig[0]);
                groupInfo.type = strip(groupConfig[1]);
                groupInfo.value = strip(value);

                version (HUNT_FM_DEBUG)
                    infof("route group: %s", groupInfo);

                string routeConfigFile = groupInfo.name ~ DEFAULT_ROUTE_CONFIG_EXT;
                routeConfigFile = buildPath(_basePath, routeConfigFile);

                if (!exists(routeConfigFile)) {
                    warningf("Config file does not exist: %s", routeConfigFile);
                } else {
                    RouteItem[] routes = load(routeConfigFile);

                    if (routes.length > 0) {
                        addGroupRoute(groupInfo, routes);
                    } else {
                        version (HUNT_DEBUG)
                            warningf("No routes defined for group %s", groupInfo.name);
                    }
                }
            }
        }
    }

    private void loadDefaultRoutes() {
        // load default routes
        string routeConfigFile = buildPath(_basePath, DEFAULT_ROUTE_CONFIG);
        if (!exists(routeConfigFile)) {
            warningf("The config file for route does not exist: %s", routeConfigFile);
        } else {
            RouteItem[] routes = load(routeConfigFile);
            _allRouteItems[RouteGroup.DEFAULT] = routes;

            RouteGroup defaultGroup = new RouteGroup();
            defaultGroup.name = RouteGroup.DEFAULT;
            defaultGroup.type = RouteGroup.DEFAULT;

            _allRouteGroups ~= defaultGroup;
        }
    }

    void withMiddleware(T)() if(is(T : MiddlewareInterface)) {
        group().withMiddleware!T();
    }
    
    void withMiddleware(string name) {
        try {
            group().withMiddleware(name);
        } catch(Exception ex) {
            warning(ex.msg);
        }
    }    
    
    void withoutMiddleware(T)() if(is(T : MiddlewareInterface)) {
        group().withoutMiddleware!T();
    }
    
    void withoutMiddleware(string name) {
        try {
            group().withoutMiddleware(name);
        } catch(Exception ex) {
            warning(ex.msg);
        }
    } 

    string createUrl(string actionId, string[string] params = null, string groupName = RouteGroup.DEFAULT) {

        if (groupName.empty)
            groupName = RouteGroup.DEFAULT;

        // find Route
        // RouteConfigManager routeConfig = serviceContainer().resolve!(RouteConfigManager);
        RouteGroup routeGroup = group(groupName);
        if (routeGroup is null)
            return null;

        RouteItem route = getRoute(groupName, actionId);
        if (route is null) {
            return null;
        }

        string url;
        if (route.isRegex) {
            if (params is null) {
                warningf("Need route params for (%s).", actionId);
                return null;
            }

            if (!route.paramKeys.empty) {
                url = route.urlTemplate;
                foreach (i, key; route.paramKeys) {
                    string value = params.get(key, null);

                    if (value is null) {
                        logWarningf("this route template need param (%s).", key);
                        return null;
                    }

                    params.remove(key);
                    url = url.replaceFirst("{" ~ key ~ "}", value);
                }
            }
        } else {
            url = route.pattern;
        }

        string groupValue = routeGroup.value;
        if (routeGroup.type == RouteGroup.HOST || routeGroup.type == RouteGroup.DOMAIN) {
            url = (_appConfig.https.enabled ? "https://" : "http://") ~ groupValue ~ url;
        } else {
            string baseUrl = strip(_appConfig.application.baseUrl, "", "/");
            url = (groupValue.empty ? baseUrl: (baseUrl ~ "/" ~ groupValue)) ~ url;
        }

        return url ~ (params.length > 0 ? ("?" ~ buildUriQueryString(params)) : "");
    }

    static string buildUriQueryString(string[string] params) {
        if (params.length == 0) {
            return "";
        }

        string r;
        foreach (k, v; params) {
            r ~= (r ? "&" : "") ~ k ~ "=" ~ v;
        }

        return r;
    }

    static RouteItem[] load(string filename) {
        import std.stdio;

        RouteItem[] items;
        auto f = File(filename);

        scope (exit) {
            f.close();
        }

        foreach (line; f.byLineCopy) {
            RouteItem item = parseOne(cast(string) line);
            if (item is null)
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
        // GET, POST    /users    module.controller.action | staticDir:wwwroot:true
        auto matched = line.match(
                regex(`([^/]+)\s+(/[\S]*?)\s+((staticDir[\:][\w|\/|\\|\:|\.]+)|([\w\.]+))`));

        if (!matched) {
            if (!line.empty()) {
                warningf("Unmatched line: %s", line);
            }
            return null;
        }

        //
        RouteItem item;
        string part3 = matched.captures[3].to!string.strip;

        // 
        if (part3.startsWith(DEFAULT_RESOURCES_ROUTE_LEADER)) {
            ResourceRouteItem routeItem = new ResourceRouteItem();
            string remaining = part3.chompPrefix(DEFAULT_RESOURCES_ROUTE_LEADER);
            string[] subParts = remaining.split(":");

            version(HUNT_HTTP_DEBUG) {
                tracef("Resource route: %s", subParts);
            }

            if(subParts.length > 1) {
                routeItem.resourcePath = subParts[0].strip();
                string s = subParts[1].strip();
                try {
                    routeItem.canListing = to!bool(s);
                } catch(Throwable t) {
                    version(HUNT_DEBUG) warning(t);
                }
            } else {
                routeItem.resourcePath = remaining.strip();
            }

            item = routeItem;
        } else {
            ActionRouteItem routeItem = new ActionRouteItem();
            // actionId
            string actionId = part3;
            string[] mcaArray = split(actionId, ".");

            if (mcaArray.length > 3 || mcaArray.length < 2) {
                logWarningf("this route config actionId length is: %d (%s)", mcaArray.length, actionId);
                return null;
            }

            if (mcaArray.length == 2) {
                routeItem.controller = mcaArray[0];
                routeItem.action = mcaArray[1];
            } else {
                routeItem.moduleName = mcaArray[0];
                routeItem.controller = mcaArray[1];
                routeItem.action = mcaArray[2];
            }
            item = routeItem;
        }

        // methods
        string methods = matched.captures[1].to!string.strip;
        methods = methods.toUpper();

        if (methods.length > 2) {
            if (methods[0] == '[' && methods[$ - 1] == ']')
                methods = methods[1 .. $ - 2];
        }

        if (methods == "*" || methods == "ALL") {
            item.methods = null;
        } else {
            item.methods = split(methods, ",");
        }

        // path
        string path = matched.captures[2].to!string.strip;
        item.path = path;
        item.pattern = mendPath(path);

        // warningf("old: %s, new: %s", path, item.pattern);

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

    static string mendPath(string path) {
        if (path.empty || path == "/")
            return "/";

        if (path[0] != '/') {
            path = "/" ~ path;
        }

        if (path[$ - 1] != '/')
            path ~= "/";

        return path;
    }
}

/**
 * Examples:
 *  # without component
 *  app.controller.attachment.attachmentcontroller.upload
 * 
 *  # with component
 *  app.component.attachment.controller.attachment.attachmentcontroller.upload
 */
string makeRouteHandlerKey(ActionRouteItem route, RouteGroup group = null) {
    string moduleName = route.moduleName;
    string controller = route.controller;

    string groupName = "";
    if (group !is null && group.name != RouteGroup.DEFAULT)
        groupName = group.name ~ ".";

    string key = format("app.%scontroller.%s%s.%scontroller.%s", moduleName.empty()
            ? "" : "component." ~ moduleName ~ ".", groupName, controller,
            controller, route.action);
    return key.toLower();
}
