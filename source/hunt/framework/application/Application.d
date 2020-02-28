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

import hunt.logging;

import hunt.http.server.HttpServer;
import hunt.http.server.WebSocketHandler;
import hunt.http.WebSocketPolicy;
import hunt.http.WebSocketCommon;

import hunt.console;

import hunt.framework.Init;
import hunt.framework.trace.Tracer;
import hunt.framework.http;
import hunt.framework.application.RouteConfig;
import hunt.framework.application.ApplicationConfig;
import hunt.framework.application.MiddlewareInterface;
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

    import std.format;
}

import poodinis;

import std.array;
import std.conv;
import std.parallelism : totalCPUs;
import std.socket : Address, parseAddress;
import std.stdio;
import std.string;

/**
 * 
 */
final class Application {

    private string _name = DEFAULT_APP_NAME;
    private string _description = DEFAULT_APP_DESCRIPTION;
    private string _ver = DEFAULT_APP_VERSION;

    private HttpServer _server;
    private ApplicationConfig _appConfig;

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
        setDefaultLogging();
        initializeProviderListener();
    }

    this(string name, string ver = DEFAULT_APP_VERSION, string description = DEFAULT_APP_DESCRIPTION) {
        _name = name;
        _ver = ver;
        _description = description;
        // serviceContainer() = new DependencyContainer();

        setDefaultLogging();
        initializeProviderListener();
    }

    void register(T)() if(is(T : ServiceProvider)) {
        if(_isBooted) {
            warning("A provider can't be registered: %s after the app has been booted.", typeid(T));
            return;
        }

        ServiceProvider provider = new T();
        provider._container = serviceContainer();
        provider.register();
        serviceContainer().register!(ServiceProvider, T)().existingInstance(provider);
        serviceContainer().autowire(provider);
        _providerListener.registered(typeid(T));
    }
    private bool _isBooted = false;

    /**
      Start the HttpServer , and block current thread.
     */
    void run(string[] args) {
        register!ConfigServiceProvider();

        if (args.length > 1) {
            ServeCommand serveCommand = new ServeCommand();
            serveCommand.onInput((ServeSignature signature) {
                version (HUNT_DEBUG)
                    tracef(signature.to!string);
                ConfigManager manager = serviceContainer().resolve!ConfigManager;
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
        // Load configuration
        // loadConfiguration();

        // 
        initializeProviders();
        _appConfig = serviceContainer().resolve!ApplicationConfig();
        
        //
        initializeLogger();

        version(WITH_HUNT_TRACE) { 
            initializeTracer();
        }

        
        // Resolve the HTTP server
        _server = serviceContainer.resolve!(HttpServer);

        //
        showLogo();

        // foreach(WebSocketBuilder b; webSocketBuilders) {
        //     b.listenWebSocket();
        // }

        // if(_broker !is null)
        //     _broker.listen();
        // foreach(WebSocketMessageBroker b; messageBrokers) {
        //     b.listen();
        // }

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

    private void showLogo() {
        Address bindingAddress = parseAddress(_appConfig.http.address, _appConfig.http.port);
        // dfmt off
        string cliText = `

 ___  ___     ___  ___     ________      _________   
|\  \|\  \   |\  \|\  \   |\   ___  \   |\___   ___\     Hunt Framework ` ~ HUNT_VERSION ~ `
\ \  \\\  \  \ \  \\\  \  \ \  \\ \  \  \|___ \  \_|     
 \ \   __  \  \ \  \\\  \  \ \  \\ \  \      \ \  \      Listening: ` ~ bindingAddress.toString() ~ `
  \ \  \ \  \  \ \  \\\  \  \ \  \\ \  \      \ \  \     TLS: ` ~ (_server.getHttpOptions().isSecureConnectionEnabled() ? "Enabled" : "Disabled") ~ `
   \ \__\ \__\  \ \_______\  \ \__\\ \__\      \ \__\    
    \|__|\|__|   \|_______|   \|__| \|__|       \|__|    https://www.huntframework.com

`;
        writeln(cliText);
        // dfmt on
        
        if (_server.getHttpOptions().isSecureConnectionEnabled())
            writeln("Try to browse https://", bindingAddress.toString());
        else
            writeln("Try to browse http://", bindingAddress.toString());
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
        _providerListener = new class ServiceProviderListener {
            void registered(TypeInfo_Class info)
            {
                version(HUNT_DEBUG) tracef("Service Provider Loaded: %s", info.toString());
            }

            void booted(TypeInfo_Class info)
            {
                version(HUNT_DEBUG) tracef("Service Provider Booted: %s", info.toString());
            }
        };
    }

    private void initializeProviders() {

        // Register all the default service providers
        register!RedisServiceProvider();
        register!TranslationServiceProvider();
        register!BreadcrumbServiceProvider();
        register!CacheServiceProvider();
        register!SessionServiceProvider();
        register!DatabaseServiceProvider();
        register!HttpServiceProvider();

        // Register all the service provided by the providers
        ServiceProvider[] providers = serviceContainer().resolveAll!(ServiceProvider);
        infof("Registering service providers (%d)...", providers.length);

        // foreach(ServiceProvider p; providers) {
        //     p.register();
        //     _providerListener.registered(typeid(p));
        //     serviceContainer().autowire(p);
        // }

        // Booting all the providers
        infof("Booting service providers (%d)...", providers.length);

        foreach(ServiceProvider p; providers) {
            p.boot();
            _providerListener.booted(typeid(p));
        }
        _isBooted = true;
    }

    private void initializeLogger() {
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
