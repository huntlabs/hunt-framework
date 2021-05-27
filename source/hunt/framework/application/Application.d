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

import hunt.framework.auth.AuthService;
import hunt.framework.application.HostEnvironment;
import hunt.framework.application.closer;
import hunt.framework.command.ServeCommand;
import hunt.framework.Init;
import hunt.framework.http;
import hunt.framework.i18n.I18n;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.config.ConfigManager;
import hunt.framework.middleware.MiddlewareInterface;
import hunt.framework.provider;
import hunt.framework.provider.listener;
import hunt.framework.routing;

import hunt.http.server.HttpServer;
import hunt.http.server.HttpServerOptions;
import hunt.http.WebSocketPolicy;
import hunt.http.WebSocketCommon;

import hunt.console;
import hunt.Functions;
import hunt.logging;
import hunt.redis;
import hunt.util.ResoureManager;
import hunt.util.worker;

import grpc.GrpcServer;
import grpc.GrpcClient;

version (WITH_HUNT_TRACE) {
    import hunt.http.HttpConnection;
    import hunt.net.util.HttpURI;
    import hunt.trace.Constrants;
    import hunt.trace.Endpoint;
    import hunt.trace.Span;
    import hunt.trace.Tracer;
    import hunt.trace.HttpSender;

    import std.format;
}

import poodinis;

import std.array;
import std.conv;
import std.meta;
import std.parallelism : totalCPUs;
import std.path;
import std.socket : Address, parseAddress;
import std.stdio;
import std.string;

alias DefaultServiceProviders = AliasSeq!(UserServiceProvider, AuthServiceProvider,
        ConfigServiceProvider, RedisServiceProvider,
        TranslationServiceProvider, CacheServiceProvider, SessionServiceProvider,
        DatabaseServiceProvider, QueueServiceProvider,
        TaskServiceProvider, HttpServiceProvider, GrpcServiceProvider,
        BreadcrumbServiceProvider, ViewServiceProvider);

/**
 * 
 */
final class Application {

    private string _name = DEFAULT_APP_NAME;
    private string _description = DEFAULT_APP_DESCRIPTION;
    private string _ver = DEFAULT_APP_VERSION;

    private HttpServer _server;
    private HttpServerOptions _serverOptions;
    private ApplicationConfig _appConfig;

    private bool _isBooted = false;
    private bool[TypeInfo] _customizedServiceProviders;
    private SimpleEventHandler _launchedHandler;
    private SimpleEventHandler _configuringHandler;
    private HostEnvironment _environment;
    private hunt.console.Command[] _commands;

    // private WebSocketPolicy _webSocketPolicy;
    // private WebSocketHandler[string] webSocketHandlerMap;

    private __gshared Application _app;

    static Application instance() {
        if (_app is null)
            _app = new Application();
        return _app;
    }

    this() {
        _environment = new HostEnvironment();
        setDefaultLogging();
        initializeProviderListener();
    }

    this(string name, string ver = DEFAULT_APP_VERSION, string description = DEFAULT_APP_DESCRIPTION) {
        _name = name;
        _ver = ver;
        _description = description;
        _environment = new HostEnvironment();

        setDefaultLogging();
        initializeProviderListener();
    }

    void register(T)() if (is(T : ServiceProvider)) {
        if (_isBooted) {
            warning("A provider can't be registered: %s after the app has been booted.", typeid(T));
            return;
        }

        ServiceProvider provider = new T();
        provider._container = serviceContainer();
        provider.register();
        serviceContainer().register!(ServiceProvider, T)().existingInstance(provider);
        serviceContainer().autowire(provider);
        _providerListener.registered(typeid(T));

        static foreach (S; DefaultServiceProviders) {
            checkCustomizedProvider!(T, S);
        }
    }

    private void tryRegister(T)() if (is(T : ServiceProvider)) {
        if (!isRegistered!(T)) {
            register!T();
        }
    }

    private void checkCustomizedProvider(T, S)() {
        static if (is(T : S)) {
            _customizedServiceProviders[typeid(S)] = true;
        }
    }

    private bool isRegistered(T)() if (is(T : ServiceProvider)) {
        auto itemPtr = typeid(T) in _customizedServiceProviders;

        return itemPtr !is null;
    }

    GrpcService grpc() {
        return serviceContainer().resolve!GrpcService();
    }

    HostEnvironment environment() {
        return _environment;
    }

    alias configuring = booting;
    Application booting(SimpleEventHandler handler) {
        _configuringHandler = handler;
        return this;
    }

    deprecated("Using booted instead.")
    alias onBooted = booted;

    Application booted(SimpleEventHandler handler) {
        _launchedHandler = handler;
        return this;
    }

    void register(hunt.console.Command cmd) {
        _commands ~= cmd;
    }

    void run(string[] args, SimpleEventHandler handler) {
        _launchedHandler = handler;
        run(args);
    }

    /**
      Start the HttpServer , and block current thread.
     */
    void run(string[] args) {
        tryRegister!ConfigServiceProvider();

        ConfigManager manager = serviceContainer().resolve!ConfigManager;
        manager.hostEnvironment = _environment;

        if(_commands.length > 0) {
            _appConfig = serviceContainer().resolve!ApplicationConfig();
            bootstrap();
            
            Console console = new Console(_description, _ver);
            console.setAutoExit(false);

            foreach(hunt.console.Command cmd; _commands) {
                console.add(cmd);
            }

            try {
                console.run(args);
            } catch(Exception ex) {
                warning(ex);
            } catch(Error er) {
                error(er);
            }

            return;
        }


        if (args.length > 1) {
            ServeCommand serveCommand = new ServeCommand();
            serveCommand.onInput((ServeSignature signature) {
                version (HUNT_DEBUG) tracef(signature.to!string);

                //
                string configPath = signature.configPath;
                if(!configPath.empty()) {
                    _environment.configPath = signature.configPath;
                }

                //
                string envName = signature.environment;

                if(envName.empty()) {
                    _environment.name = DEFAULT_RUNTIME_ENVIRONMENT;
                } else {
                    _environment.name = envName;
                }

                // loading config
                _appConfig = serviceContainer().resolve!ApplicationConfig();

                //
                string host = signature.host;
                if(!host.empty()) {
                    _appConfig.http.address = host;
                }

                //
                ushort port = signature.port;
                if(port > 0) {
                    _appConfig.http.port = signature.port;
                }

                bootstrap();
            });

            Console console = new Console(_description, _ver);
            console.setAutoExit(false);
            console.add(serveCommand);

            try {
                console.run(args);
            } catch(Exception ex) {
                warning(ex);
            } catch(Error er) {
                error(er);
            }

        } else {
            _appConfig = serviceContainer().resolve!ApplicationConfig();
            bootstrap();
        }
    }

    /**
      Stop the server.
     */
    void stop() {
        _server.stop();
    }

    // void registGrpcSerive(T)(){

    // }

    /**
     * https://laravel.com/docs/6.x/lifecycle
     */
    private void bootstrap() {
        // _appConfig = serviceContainer().resolve!ApplicationConfig();

        // 
        registerProviders();

        //
        initializeLogger();

        version (WITH_HUNT_TRACE) {
            initializeTracer();
        }

        // Resolve the HTTP server firstly
        _server = serviceContainer.resolve!(HttpServer);
        _serverOptions = _server.getHttpOptions();

        // 
        if(_configuringHandler !is null) {
            _configuringHandler();
        }

        // booting Providers
        bootProviders();

        //
        showLogo();

        // Launch the HTTP server.
        _server.start();

        // Notify that the application is ready.
        if(_launchedHandler !is null) {
            _launchedHandler();
        }
    }

    private void showLogo() {
        Address bindingAddress = parseAddress(_serverOptions.getHost(),
                cast(ushort) _serverOptions.getPort());

        // dfmt off
        string cliText = `

 ___  ___     ___  ___     ________      _________   
|\  \|\  \   |\  \|\  \   |\   ___  \   |\___   ___\     Hunt Framework ` ~ HUNT_VERSION ~ `
\ \  \\\  \  \ \  \\\  \  \ \  \\ \  \  \|___ \  \_|     
 \ \   __  \  \ \  \\\  \  \ \  \\ \  \      \ \  \      Listening: ` ~ bindingAddress.toString() ~ `
  \ \  \ \  \  \ \  \\\  \  \ \  \\ \  \      \ \  \     TLS: ` ~ (_serverOptions.isSecureConnectionEnabled() ? "Enabled" : "Disabled") ~ `
   \ \__\ \__\  \ \_______\  \ \__\\ \__\      \ \__\    
    \|__|\|__|   \|_______|   \|__| \|__|       \|__|    https://www.huntframework.com

`;
        writeln(cliText);
        // dfmt on

        if (_serverOptions.isSecureConnectionEnabled())
            writeln("Try to browse https://", bindingAddress.toString());
        else
            writeln("Try to browse http://", bindingAddress.toString());
    }

    Application providerLisener(ServiceProviderListener listener) {
        _providerListener = listener;
        return this;
    }

    ServiceProviderListener providerLisener() {
        return _providerListener;
    }

    private ServiceProviderListener _providerListener;

    private void initializeProviderListener() {
        _providerListener = new DefaultServiceProviderListener;
    }

    /**
     * Register all the default service providers
     */
    private void registerProviders() {
        // Register all the default service providers
        static foreach (T; DefaultServiceProviders) {
            static if (!is(T == ConfigServiceProvider)) {
                tryRegister!T();
            }
        }

        // Register all the service provided by the providers
        ServiceProvider[] providers = serviceContainer().resolveAll!(ServiceProvider);
        version(HUNT_DEBUG) infof("Registering all the service providers (%d)...", providers.length);

        // foreach(ServiceProvider p; providers) {
        //     p.register();
        //     _providerListener.registered(typeid(p));
        //     serviceContainer().autowire(p);
        // }

    }

    /**
     * Booting all the providers
     */
    private void bootProviders() {
        ServiceProvider[] providers = serviceContainer().resolveAll!(ServiceProvider);
        version(HUNT_DEBUG) infof("Booting all the service providers (%d)...", providers.length);

        foreach (ServiceProvider p; providers) {
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

    version (WITH_HUNT_TRACE) {
        private void initializeTracer() {

            isTraceEnabled = _appConfig.trace.enable;

            // initialize HttpSender
            httpSender().endpoint(_appConfig.trace.zipkin);
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

    // dfmtoff Some helpers
    import hunt.cache.Cache;
    import hunt.entity.EntityManager;
    import hunt.entity.EntityManagerFactory;
    import hunt.framework.breadcrumb.BreadcrumbsManager;
    import hunt.framework.queue;
    import hunt.framework.Simplify;
    import hunt.framework.task;

    ApplicationConfig config() {
        return _appConfig;
    }

    RouteConfigManager route() {
        return serviceContainer.resolve!(RouteConfigManager);
    }

    AuthService auth() {
        return serviceContainer.resolve!(AuthService);
    }

    Redis redis() {
        RedisPool pool = serviceContainer.resolve!RedisPool();
        Redis r = pool.getResource();
        registerResoure(new RedisCloser(r));
        return r;
    }

    RedisCluster redisCluster() {
        RedisCluster cluster = serviceContainer.resolve!RedisCluster();
        return cluster;
    }

    Cache cache() {
        return serviceContainer.resolve!(Cache);
    }

    TaskQueue queue() {
        return serviceContainer.resolve!(TaskQueue);
    }

    Worker task() {
        return serviceContainer.resolve!(Worker);
    }

    deprecated("Using defaultEntityManager instead.")
    EntityManager entityManager() {
        EntityManager _entityManager = serviceContainer.resolve!(EntityManagerFactory).currentEntityManager();
        registerResoure(new EntityCloser(_entityManager));
        return _entityManager;
    }

    BreadcrumbsManager breadcrumbs() {
        if(_breadcrumbs is null) {
            _breadcrumbs = serviceContainer.resolve!BreadcrumbsManager();
        }
        return _breadcrumbs;
    }
    private BreadcrumbsManager _breadcrumbs;

    I18n translation() {
        return serviceContainer.resolve!(I18n);
    }
    // dfmton
}

/**
 * 
 */
Application app() {
    return Application.instance();
}
