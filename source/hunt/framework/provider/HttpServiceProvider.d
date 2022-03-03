module hunt.framework.provider.HttpServiceProvider;

import hunt.framework.config.ApplicationConfig;
import hunt.framework.config.ConfigManager;
import hunt.framework.http.HttpErrorResponseHandler;
import hunt.http.routing.handler.DefaultErrorResponseHandler;
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

import hunt.logging.Logger;

import poodinis;

import core.time;

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
        // container.register!(HttpServerOptions).singleInstance();
        container.register!(HttpServer).initializedBy(&buildServer).singleInstance();
    }

    private HttpServer buildServer() {
        DefaultErrorResponseHandler.Default = new HttpErrorResponseHandler();
        ConfigManager manager = container.resolve!ConfigManager;
        ApplicationConfig appConfig = container.resolve!ApplicationConfig();
        auto staticFilesConfig = appConfig.staticfiles;
        // SimpleWebSocketHandler webSocketHandler = new SimpleWebSocketHandler();
        // webSocketHandler.setWebSocketPolicy(_webSocketPolicy);

        //if(conf.webSocketFactory)
        //    _wfactory = conf.webSocketFactory;

        // Building http server
        // HttpServerOptions options = new HttpServerOptions();
        HttpServer.Builder hsb = HttpServer.builder()
            .setListener(appConfig.http.port, appConfig.http.address)
            .workerThreadSize(appConfig.http.workerThreads)
            .maxRequestSize(cast(int)appConfig.http.maxHeaderSize)
            .maxFileSize(cast(int)appConfig.upload.maxSize)
            .ioThreadSize(appConfig.http.ioThreads)
            .canUpgrade(appConfig.http.canUpgrade)
            .resourceCacheTime(staticFilesConfig.cacheTime.seconds);

        version(WITH_HUNT_TRACE) {
            hsb.localServiceName(appConfig.application.name)
                .isB3HeaderRequired(appConfig.trace.b3Required);
        }


        RouteConfigManager routeConfig = container.resolve!RouteConfigManager();
        RouteItem[][RouteGroup] allRoutes = routeConfig.allRoutes;

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
            hsb.resource("/", staticFilesConfig.location, staticFilesConfig.canList, group.value, groupType);
            // }
        }

        // default static files
        hsb.resource("/", staticFilesConfig.location, staticFilesConfig.canList);
        // hsb.setDefaultRequest((RoutingContext ctx) {
        //     string content = "The resource " ~ ctx.getURI().getPath() ~ " is not found";
        //     string title = "404 - Not Found";

        //     ctx.responseHeader(HttpHeader.CONTENT_TYPE, "text/html");

        //     ctx.write("<!DOCTYPE html>")
        //         .write("<html>")
        //         .write("<head>")
        //         .write("<title>")
        //         .write(title)
        //         .write("</title>")
        //         .write("</head>")
        //         .write("<body>")
        //         .write("<h1> " ~ title ~ " </h1>")
        //         .write("<p>" ~ content ~ "</p>")
        //         .write("</body>")
        //         .end("</html>");
        // });

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
            } else if (group.type == RouteGroup.HOST || group.type == RouteGroup.DOMAIN) {
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
                version(HUNT_DEBUG) {
                    warningf("No handler found for group route {%s}, key: %s", item.toString(), handlerKey);
                }
            } else {
                version(HUNT_FM_DEBUG)
                    tracef("handler found for group route {%s}, key: %s", item.toString(), handlerKey);
                string[] methods = item.methods;
                version(HUNT_DEBUG) {
                    string methodsString = "[*]";
                    if(!methods.empty)
                        methodsString = methods.to!string();
                }

                RouterContex contex = new RouterContex();
                contex.routeGroup = group;
                contex.routeItem = item;

                if (group is null || group.type == RouteGroup.DEFAULT) {
                    version(HUNT_DEBUG) infof("adding %s %s into DEFAULT", methodsString, item.path);
                    hsb.addRoute([item.path], methods, handler, null, 
                        RouteGroupType.Default, RouterContex.stringof, contex);
                } else if (group.type == RouteGroup.HOST || group.type == RouteGroup.DOMAIN) {
                    version(HUNT_DEBUG) infof("adding %s %s into DOMAIN", methodsString, item.path);
                    hsb.addRoute([item.path], methods, handler, group.value, 
                        RouteGroupType.Host, RouterContex.stringof, contex);
                } else if (group.type == RouteGroup.PATH) {
                    version(HUNT_DEBUG) infof("adding %s %s into PATH", methodsString, item.path);
                    hsb.addRoute([item.path], methods, handler, group.value, 
                        RouteGroupType.Path, RouterContex.stringof, contex);
                } else {
                    errorf("Unknown route group type: %s", group.type);
                }
            }
        }
    }
}