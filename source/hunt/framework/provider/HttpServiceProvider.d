module hunt.framework.provider.HttpServiceProvider;

import hunt.framework.controller.Controller;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.config.ConfigManager;
import hunt.framework.Init;
import hunt.framework.provider.ServiceProvider;
import hunt.framework.routing;

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

    override void register() {
        container.register!(HttpServer)(&buildServer).singleInstance();
    }

    private HttpServer buildServer() {
        ConfigManager manager = container.resolve!ConfigManager;
        ApplicationConfig appConfig = container.resolve!ApplicationConfig();
        // SimpleWebSocketHandler webSocketHandler = new SimpleWebSocketHandler();
        // webSocketHandler.setWebSocketPolicy(_webSocketPolicy);

        //if(conf.webSocketFactory)
        //    _wfactory = conf.webSocketFactory;

        // Building http server
        // HttpServerOptions options = new HttpServerOptions();
        HttpServer.Builder hsb = HttpServer.builder()
            .setListener(appConfig.http.port, appConfig.http.address)
            .workerThreadSize(appConfig.http.workerThreads)
            .ioThreadSize(appConfig.http.ioThreads);

        RouteConfigManager routeConfig = container.resolve!RouteConfigManager();
        RouteItem[][RouteGroup] allRoutes = routeConfig.allRoutes;

        // trace(_actions.keys);

        foreach(RouteGroup group, RouteItem[] routes; allRoutes) {
            foreach (RouteItem item; routes) {
                addRoute(hsb, item, group);
            }

            RouteGroupType groupType = RouteGroupType.Host;
            if (group.type == "path") {
                groupType = RouteGroupType.Path;
            }
            // if(!isRootStaticPathAdded) {
            // default static files
            hsb.resource("/", DEFAULT_STATIC_FILES_LACATION, false, group.value, groupType);
            // }
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
            if (group is null || group.type == RouteGroup.DEFAULT) {
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
                version(HUNT_DEBUG) warningf("No handler found for group route {%s}, key: %s", item.toString(), handlerKey);
            } else {
                version(HUNT_FM_DEBUG)
                    tracef("handler found for group route {%s}, key: %s", item.toString(), handlerKey);
                if (group is null || group.type == RouteGroup.DEFAULT) {
                    version(HUNT_DEBUG) infof("adding %s", item.path);
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
}