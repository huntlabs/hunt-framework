module hunt.framework.provider.HttpServiceProvider;

import hunt.framework.application.Controller;
import hunt.framework.application.ApplicationConfig;
import hunt.framework.application.RouteConfig;
import hunt.framework.Init;
import hunt.framework.provider.ServiceProvider;

import hunt.http.routing.RoutingContext;
import hunt.http.routing.RouterManager;
import hunt.http.server.HttpServer;
import hunt.http.server.HttpServerOptions;
import hunt.http.server.WebSocketHandler;
import hunt.http.WebSocketPolicy;
import hunt.http.WebSocketCommon;

import hunt.logging.ConsoleLogger;

import poodinis;

import std.array;
import std.exception;
import std.conv;
import std.container.array;
import std.file;
import std.path;
import std.socket;
import std.stdio;
import std.string;
import std.uni;

/**
 * 
 */
class HttpServiceProvider : ServiceProvider {
    private string _configRootPath;

    override void register() {
        container.register!(HttpServer)(&buildServer).singleInstance();
    }

    private HttpServer buildServer() {

        _configRootPath = configManager().configPath();
        ApplicationConfig appConfig = container.resolve!ApplicationConfig();
        // SimpleWebSocketHandler webSocketHandler = new SimpleWebSocketHandler();
        // webSocketHandler.setWebSocketPolicy(_webSocketPolicy);

        //if(conf.webSocketFactory)
        //    _wfactory = conf.webSocketFactory;

        // Building http server
        // HttpServerOptions options = new HttpServerOptions();
        HttpServer.Builder hsb = HttpServer.builder()
            .setListener(appConfig.http.port, appConfig.http.address);

        // loading routes
        loadGroupRoutes(appConfig, (RouteGroup group, RouteItem[] routes) {
            // bool isRootStaticPathAdded = false;
            RouteConfig.allRouteItems[group.name] = routes;
            RouteConfig.allRouteGroups ~= group;

            RouteGroupType groupType = RouteGroupType.Host;
            if (group.type == "path") {
                groupType = RouteGroupType.Path;
            }

            foreach (RouteItem item; routes) {
                addRoute(hsb, item, group);
            }

            // if(!isRootStaticPathAdded) {
            // default static files
            hsb.resource("/", DEFAULT_STATIC_FILES_LACATION, false, group.value, groupType);
            // }
        });

        // load default routes
        string routeConfigFile = buildPath(_configRootPath, DEFAULT_ROUTE_CONFIG);
        if (!exists(routeConfigFile)) {
            warningf("The config file for route does not exist: %s", routeConfigFile);
        } else {
            RouteItem[] routes = RouteConfig.load(routeConfigFile);
            RouteConfig.allRouteItems[DEFAULT_ROUTE_GROUP] = routes;

            RouteGroup defaultGroup = new RouteGroup();
            defaultGroup.name = DEFAULT_ROUTE_GROUP;
            defaultGroup.type = RouteGroup.DEFAULT;

            RouteConfig.allRouteGroups ~= defaultGroup;

            foreach (RouteItem item; routes) {
                addRoute(hsb, item, null);
            }
        }

        // default static files
        hsb.resource("/", DEFAULT_STATIC_FILES_LACATION, false);
        return hsb.build();
    }


    private void addRoute(HttpServer.Builder hsb, RouteItem item, RouteGroup group) {
        ResourceRouteItem resourceItem = cast(ResourceRouteItem) item;

        // add route for static files 
        if (resourceItem !is null) {
            // if(resourceItem.path == "/") isRootStaticPathAdded = true;
            if (group is null) {
                hsb.resource(resourceItem.path, resourceItem.resourcePath,
                        resourceItem.canListing);
            } else if (group.type == RouteGroup.HOST) {
                hsb.resource(resourceItem.path, resourceItem.resourcePath,
                        resourceItem.canListing, group.value, RouteGroupType.Host);
            } else if (group.type == RouteGroup.PATH) {
                hsb.resource(resourceItem.path, resourceItem.resourcePath,
                        resourceItem.canListing, group.value, RouteGroupType.Path);
            } else {
                errorf("Unknown route group type: %s", group.type);
            }
        } else { // add route for controller action
            string handlerKey = makeRouteHandlerKey(cast(ActionRouteItem) item, group);
            RoutingHandler handler = getRouteHandler(handlerKey);
            // warning(item.toString());
            if (handler is null) {
                warningf("No handler found for group route {%s}", item.toString());
            } else {
                version (HUNT_DEBUG)
                    tracef("handler found for group route {%s}", item.toString());
                if (group is null) {
                    infof("adding %s", item.path);
                    hsb.addRoute([item.path], item.methods, handler);
                } else if (group.type == RouteGroup.HOST) {
                    hsb.addRoute([item.path], item.methods, handler,
                            group.value, RouteGroupType.Host);
                } else if (group.type == RouteGroup.PATH) {
                    hsb.addRoute([item.path], item.methods, handler,
                            group.value, RouteGroupType.Path);
                } else {
                    errorf("Unknown route group type: %s", group.type);
                }
            }
        }
    }

    private void loadGroupRoutes(ApplicationConfig conf, RouteGroupHandler handler) {
        if (conf.route.groups.empty)
            return;

        assert(handler !is null);
        version (HUNT_DEBUG)
            info(conf.route.groups);

        string[] groupConfig;
        foreach (v; split(conf.route.groups, ',')) {
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

                string routeConfigFile = groupInfo.name ~ ROUTE_CONFIG_EXT;
                routeConfigFile = buildPath(_configRootPath, routeConfigFile);

                if (!exists(routeConfigFile)) {
                    warningf("Config file does not exist: %s", routeConfigFile);
                } else {
                    RouteItem[] routes = RouteConfig.load(routeConfigFile);

                    if (routes.length > 0) {
                        handler(groupInfo, routes);
                    } else {
                        version (HUNT_DEBUG)
                            warningf("No routes defined for group %s", groupInfo.name);
                    }
                }
            }
        }

    }    
}