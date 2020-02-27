/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.application.Application;

import hunt.collection;
import hunt.Exceptions;
import hunt.Functions;
import hunt.io.Common;
import hunt.logging;
import hunt.net.NetUtil;

import hunt.http.routing.RoutingContext;
import hunt.http.routing.RouterManager;
import hunt.http.server.HttpServer;
import hunt.http.server.HttpServerOptions;
import hunt.http.server.WebSocketHandler;
import hunt.http.WebSocketPolicy;
import hunt.http.WebSocketCommon;

import hunt.cache;
import hunt.console;
import hunt.entity;
import hunt.event;

// import hunt.event.EventLoopGroup;
import hunt.Functions;

import hunt.framework.Init;
import hunt.framework.trace.Tracer;
import hunt.framework.http;
import hunt.framework.i18n;
import hunt.framework.application.Controller;
import hunt.framework.application.RouteConfig;
import hunt.framework.application.ApplicationConfig;
import hunt.framework.application.MiddlewareInterface;
import hunt.framework.application.BreadcrumbsManager;
import hunt.framework.application.Breadcrumbs;
import hunt.framework.application.ServeCommand;
import hunt.framework.provider;

import hunt.redis;

version (WITH_HUNT_TRACE) {
    import hunt.net.util.HttpURI;
    import hunt.trace.Constrants;
    import hunt.trace.Endpoint;
    import hunt.trace.Span;
    import hunt.trace.Tracer;
    import hunt.trace.HttpSender;
    import hunt.framework.trace.Tracer;

    import std.conv;
    import std.format;
}

import poodinis;

import std.array;
import std.exception;
import std.conv;
import std.container.array;
import std.file;
import std.path;
import std.parallelism;
import std.socket;
import std.stdio;
import std.string;
import std.uni;

/**
 * 
 */
final class Application {

    private string _name = "HuntApp";
    private string _description = "An application bootstrapped by Hunt Framework";
    private string _ver = "1.0.0";

    private string _configRootPath;
    private Address _bindingAddress;
    private HttpServer _server;
    private ApplicationConfig _appConfig;
    private EntityManagerFactory _entityManagerFactory;

    // private Cache _cache;
    private SessionStorage _sessionStorage;
    private WebSocketPolicy _webSocketPolicy;
    private WebSocketHandler[string] webSocketHandlerMap;
    private MiddlewareInterface[string][string] _groupMiddlewares;

    private __gshared Application _app;

    static Application instance() {
        if (_app is null)
            _app = new Application();
        return _app;
    }

    this() {
        this("HuntApp", "1.0.0", "An application bootstrapped by Hunt Framework");
    }

    this(string name, string ver = "1.0.0", string description = "") {
        _name = name;
        _ver = ver;
        _description = description;
        // serviceContainer() = new DependencyContainer();

        setDefaultLogging();
    }

    // shared(DependencyContainer) serviceContainer() {
    //     return serviceContainer();
    // }
    // private shared DependencyContainer serviceContainer();

    void register(T)() if(is(T : ServiceProvider)) {
        if(_isBooted) {
            warning("A provider can't be registered: %s after the app has been booted.", typeid(T));
            return;
        }

        ServiceProvider provider = new T();
        provider._container = serviceContainer();
        // provider.register();
        serviceContainer().register!(ServiceProvider, T)().existingInstance(provider);
        // serviceContainer().autowire(provider);
    }
    private bool _isBooted = false;

    EntityManagerFactory entityManagerFactory() {
        return _entityManagerFactory;
    }

    SessionStorage sessionStorage() {
        return _sessionStorage;
    }

    // Cache cache() {
    //     return _cache;
    // }

    // @property HttpServer server() {
    //     return _server;
    // }


    /**
      Start the HttpServer , and block current thread.
     */
    void run(string[] args) {

        if (args.length > 1) {
            ServeCommand serveCommand = new ServeCommand();
            serveCommand.onInput((ServeSignature signature) {
                version (HUNT_DEBUG)
                    tracef(signature.to!string);
                ConfigManager manager = configManager();
                manager.configPath = signature.configPath;
                manager.configFile = signature.configFile;
                manager.load();
                manager.httpBind(signature.host, signature.port);

                bootstrap();
            });

            Console console = new Console(_description, _ver);
            console.setAutoExit(false);
            console.add(serveCommand);
            console.run(args);

        } else {
            bootstrap();
        }
    }

    /**
      Stop the server.
     */
    void stop() {
        _server.stop();
    }

    /**
     * https://laravel.com/docs/6.x/lifecycle
     */
    private void bootstrap() {
        // LoadEnvironmentVariables
        // Load configuration
        loadConfiguration();
        
        //
        initializeLogger();

        // initializeCache();
        initializeDatabase();
        // initializeSessionStorage();
        version(WITH_HUNT_TRACE) { 
            initializeTracer();
        }
        initializeWorkerPool();
        initializeHttpServer();

        //
        showLogo();

        // 
        initializeProviders();

        // foreach(WebSocketBuilder b; webSocketBuilders) {
        //     b.listenWebSocket();
        // }

        // if(_broker !is null)
        //     _broker.listen();
        // foreach(WebSocketMessageBroker b; messageBrokers) {
        //     b.listen();
        // }


        if (_server.getHttpOptions().isSecureConnectionEnabled())
            writeln("Try to browse https://", _bindingAddress.toString());
        else
            writeln("Try to browse http://", _bindingAddress.toString());

        _server.start();
    }

    // Application registerWebSocket(string uri, WebSocketHandler webSocketHandler) {
    //     webSocketHandlerMap[uri] = webSocketHandler;
    //     return this;
    // }

    // Application webSocketPolicy(WebSocketPolicy w) {
    //     this._webSocketPolicy = w;
    //     return this;
    // }

    // WebSocketBuilder webSocket(string path) {
    //     WebSocketBuilder webSocketBuilder = new WebSocketBuilder(path);
    //     webSocketBuilders.insertBack(webSocketBuilder);
    //     return webSocketBuilder;
    // }

    Application addGroupMiddleware(MiddlewareInterface mw, string group = "default") {
        _groupMiddlewares[group][mw.name()] = mw;
        return this;
    }

    MiddlewareInterface[string] getGroupMiddlewares(string group) {
        if (group in _groupMiddlewares)
            return _groupMiddlewares[group];
        else
            return null;
    }

    string createUrl(string mca, string[string] params = null, string group = null) {

        if (group.empty)
            group = DEFAULT_ROUTE_GROUP;

        // find Route
        RouteGroup routeGroup = RouteConfig.getRouteGroupe(group);
        if (routeGroup is null)
            return null;

        RouteItem route = RouteConfig.getRoute(group, mca);
        if (route is null) {
            return null;
        }

        string url;
        if (route.isRegex) {
            if (params.length == 0) {
                logWarningf("this route need params (%s).", mca);
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
        if (routeGroup.type == RouteGroup.HOST) {
            url = (_appConfig.https.enabled ? "https://" : "http://") ~ groupValue ~ url;
        } else {
            url = (!groupValue.empty
                    ? (_appConfig.application.baseUrl ~ groupValue) : strip(
                        _appConfig.application.baseUrl, "", "/")) ~ url;
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

    private void loadConfiguration() {
        version(HUNT_DEBUG) infof("Loading config...");

        _configRootPath = configManager().configPath();
        _appConfig = configManager().config();
        serviceContainer().register!(ApplicationConfig)().existingInstance(_appConfig);
        _bindingAddress = parseAddress(_appConfig.http.address, _appConfig.http.port);
    }

    private void showLogo() {
        // dfmt off
        string cliText = `

 ___  ___     ___  ___     ________      _________   
|\  \|\  \   |\  \|\  \   |\   ___  \   |\___   ___\     Hunt Framework ` ~ HUNT_VERSION ~ `
\ \  \\\  \  \ \  \\\  \  \ \  \\ \  \  \|___ \  \_|     
 \ \   __  \  \ \  \\\  \  \ \  \\ \  \      \ \  \      Listening: ` ~ _bindingAddress.toString() ~ `
  \ \  \ \  \  \ \  \\\  \  \ \  \\ \  \      \ \  \     TLS: ` ~ (_server.getHttpOptions().isSecureConnectionEnabled() ? "Enabled" : "Disabled") ~ `
   \ \__\ \__\  \ \_______\  \ \__\\ \__\      \ \__\    
    \|__|\|__|   \|_______|   \|__| \|__|       \|__|    https://www.huntframework.com

`;
        writeln(cliText);
        // dfmt on
    }

    Application providerLisener(ServiceProviderListener listener)
    {
        _providerListener = listener;
        return this;
    }

    ServiceProviderListener providerLisener()
    {
        return _providerListener;
    }
    private ServiceProviderListener _providerListener;

    private void initializeProviderListener()
    {
        if (_providerListener is null)
        {
            _providerListener = new class ServiceProviderListener {
                void registered(TypeInfo_Class info)
                {
                    warningf("Service Provider Loaded: %s", info.toString());
                }

                void booted(TypeInfo_Class info)
                {
                    warningf("Service Provider Booted: %s", info.toString());
                }
            };
        }
    }

    private void initializeProviders() {
        initializeProviderListener();

        // Register all the default service providers
        register!RedisServiceProvider();
        register!I18nServiceProvider();
        register!BreadcrumbServiceProvider();
        register!CacheServiceProvider();
        register!SessionServiceProvider();

        // Register all the service provided by the providers
        ServiceProvider[] providers = serviceContainer().resolveAll!(ServiceProvider);
        infof("Registering service providers (%d)...", providers.length);

        foreach(ServiceProvider p; providers) {
            p.register();
            _providerListener.registered(typeid(p));
            serviceContainer().autowire(p);
        }

        // Booting all the providers
        infof("Booting service providers (%d)...", providers.length);

        foreach(ServiceProvider p; providers) {
            p.boot();
            _providerListener.booted(typeid(p));
        }
        _isBooted = true;
    }

    private void initializeLogger() {
        // ApplicationConfig appConfig = serviceContainer().resolve!ApplicationConfig();
        ApplicationConfig.LoggingConfig conf = _appConfig.logging;
        version (HUNT_DEBUG) {
            hunt.logging.LogLevel level = hunt.logging.LogLevel.Trace;
            switch (toLower(conf.level)) {
            case "critical":
            case "error":
                level = hunt.logging.LogLevel.Error;
                break;
            case "fatal":
                level = hunt.logging.LogLevel.Fatal;
                break;
            case "warning":
                level = hunt.logging.LogLevel.Warning;
                break;
            case "info":
                level = hunt.logging.LogLevel.Info;
                break;
            case "off":
                level = hunt.logging.LogLevel.Off;
                break;
            default:
                break;
            }
        } else {
            hunt.logging.LogLevel level = hunt.logging.LogLevel.LOG_DEBUG;
            switch (toLower(conf.level)) {
            case "critical":
            case "error":
                level = hunt.logging.LogLevel.LOG_ERROR;
                break;
            case "fatal":
                level = hunt.logging.LogLevel.LOG_FATAL;
                break;
            case "warning":
                level = hunt.logging.LogLevel.LOG_WARNING;
                break;
            case "info":
                level = hunt.logging.LogLevel.LOG_INFO;
                break;
            case "off":
                level = hunt.logging.LogLevel.LOG_Off;
                break;
            default:
                break;
            }
        }

        version (HUNT_DEBUG) {
        } else {
            LogConf logconf;
            logconf.level = level;
            logconf.disableConsole = conf.disableConsole;

            if (!conf.file.empty)
                logconf.fileName = buildPath(conf.path, conf.file);

            logconf.maxSize = conf.maxSize;
            logconf.maxNum = conf.maxNum;

            logLoadConf(logconf);
        }        
    }


    // private void initializeCache() {
        // _cache = CacheFactory.create(_appConfig.cache);
    // }

    private void initializeDatabase() {
        ApplicationConfig.DatabaseConf config = _appConfig.database;
        if (!config.defaultOptions.enabled) {
            warning("The database is disabled.");
            return;
        }

        if (config.defaultOptions.url.empty) {
            logWarning("No database configured!");
        } else {
            import hunt.entity.EntityOption;

            auto option = new EntityOption;

            // database options
            option.database.driver = config.defaultOptions.driver;
            option.database.host = config.defaultOptions.host;
            option.database.username = config.defaultOptions.username;
            option.database.password = config.defaultOptions.password;
            option.database.port = config.defaultOptions.port;
            option.database.database = config.defaultOptions.database;
            option.database.charset = config.defaultOptions.charset;
            option.database.prefix = config.defaultOptions.prefix;

            // database pool options
            option.pool.minIdle = config.pool.minIdle;
            option.pool.idleTimeout = config.pool.idleTimeout;
            option.pool.maxPoolSize = config.pool.maxPoolSize;
            option.pool.minPoolSize = config.pool.minPoolSize;
            option.pool.maxLifetime = config.pool.maxLifetime;
            option.pool.connectionTimeout = config.pool.connectionTimeout;
            option.pool.maxConnection = config.pool.maxConnection;
            option.pool.minConnection = config.pool.minConnection;

            infof("using database: %s", config.defaultOptions.driver);
            _entityManagerFactory = Persistence.createEntityManagerFactory("default", option);
        }
    }

    // private void initializeSessionStorage() {
    //     ApplicationConfig.SessionConf config = _appConfig.session;
    //     _sessionStorage = new SessionStorage(_cache);

    //     _sessionStorage.setPrefix(config.prefix);
    //     _sessionStorage.expire = config.expire;
    // }

    version(WITH_HUNT_TRACE) {

        private void initializeTracer() {
            _localServiceName = _appConfig.application.name;
            isTraceEnabled = _appConfig.trace.enable;
            // _isB3HeaderRequired = config.trace.b3Required;

            // initialize HttpSender
            httpSender().endpoint(_appConfig.trace.zipkin);
        }
        
        private void initializeTracer(Request request, HttpConnection connection) {

            if(!isTraceEnabled) return;

            import std.socket;
            string reqPath = request.getURI().getPath();
            Tracer tracer;

            string b3 = request.header("b3");
            if(b3.empty()) {
                if(_isB3HeaderRequired) return;

                tracer = new Tracer(reqPath);
            } else {
                version(HUNT_HTTP_DEBUG) {
                    warningf("initializing tracer for %s, with %s", reqPath, b3);
                }

                tracer = new Tracer(reqPath, b3);
            }

            Span span = tracer.root;
            span.initializeLocalEndpoint(_localServiceName);

            // 
            Address remote = connection.getRemoteAddress;
            EndPoint remoteEndpoint = new EndPoint();
            remoteEndpoint.ipv4 = remote.toAddrString();
            remoteEndpoint.port = remote.toPortString().to!int;
            span.remoteEndpoint = remoteEndpoint;
            //

            span.start();
            request.tracer = tracer;
        } 

        private string _localServiceName;
        private bool _isB3HeaderRequired = true;
    } 

    private void initializeWorkerPool() {
        // Worker pool
        int minThreadCount = totalCPUs / 4 + 1;
        if (_appConfig.http.workerThreads == 0)
            _appConfig.http.workerThreads = minThreadCount;

        if (_appConfig.http.workerThreads < minThreadCount) {
            warningf("It's better to set the number of worker threads >= %d. The current is: %d",
                    minThreadCount, _appConfig.http.workerThreads);
            // _appConfig.http.workerThreads = minThreadCount;
        }

        if (_appConfig.http.workerThreads <= 1) {
            _appConfig.http.workerThreads = 2;
        }
    }

    private void initializeHttpServer() {
        // SimpleWebSocketHandler webSocketHandler = new SimpleWebSocketHandler();
        // webSocketHandler.setWebSocketPolicy(_webSocketPolicy);

        //if(conf.webSocketFactory)
        //    _wfactory = conf.webSocketFactory;

        // Building http server
        // HttpServerOptions options = new HttpServerOptions();
        HttpServer.Builder hsb = HttpServer.builder()
            .setListener(_appConfig.http.port, _appConfig.http.address);

        // loading routes
        loadGroupRoutes(_appConfig, (RouteGroup group, RouteItem[] routes) {
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
        _server = hsb.build();
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

    private void loadGroupRoutes(const ref ApplicationConfig conf, RouteGroupHandler handler) {
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
    
    private void setDefaultLogging() {
        version (HUNT_DEBUG) {
        } else {
            LogConf logconf;
            logconf.level = hunt.logging.LogLevel.LOG_Off;
            logconf.disableConsole = true;
            logLoadConf(logconf);
        }
    }

}

/**
 * 
 */
Application app() {
    return Application.instance();
}
