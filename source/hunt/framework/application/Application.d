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


import hunt.http.codec.http.model;
import hunt.http.codec.http.stream;
import hunt.http.codec.websocket.frame.Frame;
import hunt.http.codec.websocket.stream.AbstractWebSocketBuilder;
import hunt.http.codec.websocket.stream.WebSocketConnection;
import hunt.http.codec.websocket.stream.WebSocketPolicy;
import hunt.http.server;

import hunt.redis;

import hunt.framework.application.Dispatcher;
import hunt.framework.application.ApplicationContext;
import hunt.framework.Init;
import hunt.framework.routing;
import hunt.framework.security.acl.Manager;
import hunt.framework.websocket.WebSocketMessageBroker;
import hunt.framework.trace.Tracer;

public import hunt.framework.http;
public import hunt.framework.i18n;
public import hunt.framework.application.ApplicationConfig;
public import hunt.framework.application.MiddlewareInterface;

import hunt.framework.application.BreadcrumbsManager;
import hunt.framework.application.Breadcrumbs;

public import hunt.cache;

version(WITH_HUNT_ENTITY)
{
    public import hunt.entity;
}


version(WITH_HUNT_TRACE) {
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

public import hunt.event;
public import hunt.event.EventLoopGroup;

import hunt.Functions;

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

alias BreadcrumbsHandler = void delegate(BreadcrumbsManager manager);

/**
*/
final class Application : ApplicationContext {
    static Application getInstance() @property {
        if (_app is null)
            _app = new Application();
        return _app;
    }

    Address binded() {
        return addr;
    }

    // enable i18n
    Application enableLocale(string resPath = DEFAULT_LANGUAGE_PATH) {
        I18n i18n = I18n.instance();

        i18n.defaultLocale = configManager().config().application.defaultLanguage;
        i18n.loadLangResources(resPath);

        return this;
    }

    Application onBreadcrumbsInitializing(BreadcrumbsHandler handler)
    {
        _breadcrumbsHandler = handler;

        return this;
    }

    // void setWebSocketFactory(WebSocketFactory webfactory)
    // {
    //     _wfactory = webfactory;
    // }

    version (NO_TASKPOOL) {
    }
    else {
        @property TaskPool taskPool() {
            return _tpool;
        }
    }

    /// get the router.
    @property Router router() {
        return this._dispatcher.router();
    }

    @property HttpServer server() {
        return _server;
    }

    @property EventLoopGroup loopGroup() {
        return NetUtil.defaultEventLoopGroup();
    }

    private void initDatabase(ApplicationConfig.DatabaseConf config)
    {
        version(WITH_HUNT_ENTITY)
        {
            if (config.defaultOptions.url.empty)
            {
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
        else
        {
            if (config.defaultOptions.enabled)
            {
                logWarning("Please add hunt-entity to dependency.");
            }
        }
    }

    private void initCache(CacheOption option) {
        _cache = CacheFactory.create(option);
    }

    private void initSessionStorage(ApplicationConfig.SessionConf config) {
        _sessionStorage = new SessionStorage(_cache);

        _sessionStorage.setPrefix(config.prefix);
        _sessionStorage.expire = config.expire;
    }

    version(WITH_HUNT_ENTITY)
    {
        EntityManagerFactory entityManagerFactory() {
            return _entityManagerFactory;
        }
    }

    SessionStorage sessionStorage() {
        return _sessionStorage;
    }

    Cache cache() {
        return _cache;
    }

    AccessManager accessManager() @property {
        return _accessManager;
    }

    /**
      Start the HttpServer , and block current thread.
     */
    void run() {
        start();
    }

    void setConfig(ApplicationConfig config) {
        setLogConfig(config.logging);
        enableLocale();
        upConfig(config);

        // setting redis
        auto redisSettings = config.redis;
        if(redisSettings.pool.enabled) {
            RedisPoolConfig poolConfig = new RedisPoolConfig();
            poolConfig.host = redisSettings.host;
            poolConfig.port = cast(int)redisSettings.port;
            poolConfig.password = redisSettings.password;
            poolConfig.database = cast(int)redisSettings.database;
            poolConfig.soTimeout = cast(int)redisSettings.pool.maxIdle;

            hunt.redis.RedisPool.defalutPoolConfig = poolConfig;
        }

        //setRedis(config.redis);
        //setMemcache(config.memcache);
        version(WITH_HUNT_ENTITY) {
            if (config.database.defaultOptions.enabled) {
                initDatabase(config.database);
            } else {
                warning("The database is disabled.");
            }
        }
        initCache(config.cache);
        initSessionStorage(config.session);
        _accessManager = new AccessManager(cache() , config.application.name , config.session.prefix, config.session.expire);

        version(WITH_HUNT_TRACE)
        {
            _localServiceName = config.application.name;
            isTraceEnabled = config.trace.enable;
            _isB3HeaderRequired = config.trace.b3Required;

            // initialize HttpSender
            httpSender().endpoint(config.trace.zipkin);
        }
    }

    private string _localServiceName;

    private void initilizeBreadcrumbs() {
        BreadcrumbsManager breadcrumbs = breadcrumbsManager();
        if(_breadcrumbsHandler !is null) {
            _breadcrumbsHandler(breadcrumbs);
        }

    }

    void start() {
        foreach(WebSocketBuilder b; webSocketBuilders) {
            b.listenWebSocket();
        }

        if(_broker !is null)
            _broker.listen();
        // foreach(WebSocketMessageBroker b; messageBrokers) {
        //     b.listen();
        // }

        initilizeBreadcrumbs();

        string cliText = `

 ___  ___     ___  ___     ________      _________   
|\  \|\  \   |\  \|\  \   |\   ___  \   |\___   ___\     Hunt Framework ` ~ HUNT_VERSION ~ `
\ \  \\\  \  \ \  \\\  \  \ \  \\ \  \  \|___ \  \_|     
 \ \   __  \  \ \  \\\  \  \ \  \\ \  \      \ \  \      Listening: ` ~ addr.toString() ~ `
  \ \  \ \  \  \ \  \\\  \  \ \  \\ \  \      \ \  \     TLS: ` ~ (_server.getHttpOptions().isSecureConnectionEnabled() ? "Enabled" : "Disabled") ~ `
   \ \__\ \__\  \ \_______\  \ \__\\ \__\      \ \__\    
    \|__|\|__|   \|_______|   \|__| \|__|       \|__|    https://www.huntframework.com

`;
        writeln(cliText);

        if (_server.getHttpOptions().isSecureConnectionEnabled())
            writeln("Try to browse https://", addr.toString());
        else
            writeln("Try to browse http://", addr.toString());

        _server.start();
    }

    /**
      Stop the server.
     */
    void stop() {
        _server.stop();
    }

    void publishEvent(Object event) {
        // implementationMissing(false);
        // TODO: Tasks pending completion -@zxp at 11/13/2018, 3:26:56 PM
        // 
    }

    Application registerWebSocket(string uri, WebSocketHandler webSocketHandler) {
        webSocketHandlerMap[uri] = webSocketHandler;
        return this;
    }

    Application webSocketPolicy(WebSocketPolicy w) {
        this._webSocketPolicy = w;
        return this;
    }

    WebSocketBuilder webSocket(string path) {
        WebSocketBuilder webSocketBuilder = new WebSocketBuilder(path);
        webSocketBuilders.insertBack(webSocketBuilder);
        return webSocketBuilder;
    }

    WebSocketMessageBroker withStompBroker() {
        if(_broker is null) {
            WebSocketMessageBroker broker = new WebSocketMessageBroker(this);
            this._broker = broker;
        }
        return _broker;
    }
    private WebSocketMessageBroker _broker;

    WebSocketMessageBroker getStompBroker() {
        return _broker;
    }

    Application addGroupMiddleware(MiddlewareInterface mw , string group = "default")
    {
        _groupMiddlewares[group][mw.name()] = mw;
        return this;
    }

    MiddlewareInterface[string] getGroupMiddlewares(string group)
    {
        if(group in _groupMiddlewares)
            return _groupMiddlewares[group];
        else
         return null;
    }

    private void handleRequest(Request req) nothrow {
        this._dispatcher.dispatch(req);
    }

    // private Action1!Request _headerComplete;
    private Action3!(int, string, Request) _badMessage;
    private Action1!Request _earlyEof;
    // private Action1!HttpConnection _acceptConnection;
    // private Action2!(Request, HttpServerConnection) tunnel;

    private ServerHttpHandlerAdapter buildHttpHandlerAdapter() {
        ServerHttpHandlerAdapter adapter = new ServerHttpHandlerAdapter();
        adapter.acceptConnection((HttpConnection c) {
            version (HUNT_DEBUG)
                logDebugf("new request from: %s", c.getTcpConnection().getRemoteAddress().toString());

            // }).acceptHttpTunnelConnection((request, response, ot, connection) {
            //     Request r = new Request(request, response, ot, cast(HttpConnection)connection, _sessionStorage);
            //     request.setAttachment(r);
            //     if (tunnel !is null) {
            //         tunnel(r, connection);
            //     }
            //     return true;
        }).headerComplete((request, response, ot, connection) {
            Request r = new Request(request, response, ot, connection, _sessionStorage);
            request.setAttachment(r);
            // if (_headerComplete !is null) {
            //     _headerComplete(r);
            // }
            r.onHeaderCompleted();
            version(WITH_HUNT_TRACE) initializeTracer(r, connection);
            return false;
        }).content((buffer, request, response, ot, connection) {
            Request r = cast(Request) request.getAttachment();
            if (r !is null)
                r.onContent(buffer);
            return false;
        }).contentComplete((request, response, ot, connection)  {
            Request r = cast(Request) request.getAttachment();
            if (r !is null) {
                r.onContentCompleted();
            }

            return false;
        }).messageComplete((request, response, ot, connection) {
            Request r = cast(Request) request.getAttachment();
            r.onMessageCompleted();
            handleRequest(r);

            version(WITH_HUNT_TRACE) endTraceSpan(r, response.getStatus());
            // IO.close(r.getResponse());
            return true;
        }).badMessage((status, reason, request, response, ot, connection) {
            if (_badMessage !is null) {
                Request r;
                if (request.getAttachment() !is null) {
                    r = cast(Request) request.getAttachment();
                    _badMessage(status, reason, r);
                } else {
                    r = new Request(request, response, ot, connection, _sessionStorage);
                    request.setAttachment(r);
                    _badMessage(status, reason, r);
                }

                version(WITH_HUNT_TRACE) endTraceSpan(r, status, reason);
            }
        }).earlyEOF((request, response, ot, connection) {
            if (_earlyEof !is null) {
                if (request.getAttachment() !is null) {
                    Request r = cast(Request) request.getAttachment();
                    _earlyEof(r);
                }
                else {
                    Request r = new Request(request, response, ot, connection, _sessionStorage);
                    request.setAttachment(r);
                    _earlyEof(r);
                }
            }
        });
        return adapter;
    }


version(WITH_HUNT_TRACE) {
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


    // private void endTraceSpan(Request request, int status, string message = null) {

    //     if(!isTraceEnabled) return;

    //     Tracer tracer = request.tracer;
    //     if(tracer is null) {
    //         version(HTTP_DEBUG) warning("no tracer defined");
    //         return;
    //     }

    //     HttpURI uri = request.getURI();
    //     string[string] tags;
    //     tags[HTTP_HOST] = uri.getHost();
    //     tags[HTTP_URL] = uri.getPathQuery();
    //     tags[HTTP_PATH] = uri.getPath();
    //     tags[HTTP_REQUEST_SIZE] = request.getContentLength().to!string();
    //     tags[HTTP_METHOD] = request.methodAsString();

    //     Span span = tracer.root;
    //     if(span !is null) {
    //         tags[HTTP_STATUS_CODE] = to!string(status);
    //         traceSpanAfter(span, tags, message);
    //         httpSender().sendSpans(span);
    //     } else {
    //         warning("No span sent");
    //     }
    // }
    
    // private bool isTraceEnabled = true;          
} else {
    // private bool isTraceEnabled = false;
}
    private bool _isB3HeaderRequired = true;

    private void buildHttpServer(ApplicationConfig conf) {
        version(HUNT_DEBUG) logDebug("addr:", conf.http.address, ":", conf.http.port);

        SimpleWebSocketHandler webSocketHandler = new SimpleWebSocketHandler();
        webSocketHandler.setWebSocketPolicy(_webSocketPolicy);

        HttpServerOptions options = new HttpServerOptions();

        _server = new HttpServer(conf.http.address, conf.http.port,
                options, buildHttpHandlerAdapter(), webSocketHandler);
    }

private:
    void upConfig(ApplicationConfig conf) {
        addr = parseAddress(conf.http.address, conf.http.port);

        version (NO_TASKPOOL) {
            // NOTHING
        }
        else {
            int minThreadCount = totalCPUs/4 + 1;
            if(conf.http.workerThreads == 0)
                conf.http.workerThreads = minThreadCount;
                
            if(conf.http.workerThreads < minThreadCount) {
                warningf("It's better to make the number of worker threads >= %d. The current value is: %d",
                    minThreadCount, conf.http.workerThreads);
                // conf.http.workerThreads = minThreadCount;
            }
            _tpool = new TaskPool(conf.http.workerThreads);
            _tpool.isDaemon = true;
        }

        buildHttpServer(conf);

        //if(conf.webSocketFactory)
        //    _wfactory = conf.webSocketFactory;

        version(HUNT_DEBUG) info(conf.route.groups);

        version (NO_TASKPOOL) {
        }
        else {
            this._dispatcher.setWorkers(_tpool);
        }
        // init dispatcer and routes
        if (conf.route.groups) {
            import std.array : split;
            import std.string : strip;

            string[] groupConfig;

            foreach (v; split(conf.route.groups, ',')) {
                groupConfig = split(v, ":");

                if (groupConfig.length == 3 || groupConfig.length == 4) {
                    string value = groupConfig[2];

                    if (groupConfig.length == 4) {
                        if (std.conv.to!int(groupConfig[3]) > 0) {
                            value ~= ":" ~ groupConfig[3];
                        }
                    }

                    this._dispatcher.addRouteGroup(strip(groupConfig[0]),
                            strip(groupConfig[1]), strip(value));

                    continue;
                }

                logWarningf("Group config format error ( %s ).", v);
            }
        }

        this._dispatcher.loadRouteGroups();
    }



    void setLogConfig(ref ApplicationConfig.LoggingConfig conf) {
        version(HUNT_DEBUG) {
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

        version(HUNT_DEBUG) {}
        else {
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

    /**
    Raw WebSocket Request Handler
    */
    class WebSocketBuilder : AbstractWebSocketBuilder {
        protected string path;
        protected Action1!(WebSocketConnection) _connectHandler;

        this(string path) {
            this.path = path;
        }

        WebSocketBuilder onConnect(Action1!(WebSocketConnection) handler) {
            this._connectHandler = handler;
            return this;
        }

        override WebSocketBuilder onText(Action2!(string, WebSocketConnection) handler) {
            super.onText(handler);
            return this;
        }

        override WebSocketBuilder onData(Action2!(ByteBuffer, WebSocketConnection) handler) {
            super.onData(handler);
            return this;
        }

        override WebSocketBuilder onError(Action2!(Throwable, WebSocketConnection) handler) {
            super.onError(handler);
            return this;
        }

        alias onError = AbstractWebSocketBuilder.onError;

        void start() {
            this.outer.start();
        }

        private void listenWebSocket() {
            this.outer.registerWebSocket(path, new class WebSocketHandler {

                override void onConnect(WebSocketConnection webSocketConnection) {
                    if(_connectHandler !is null) 
                        _connectHandler(webSocketConnection);
                }

                override void onFrame(Frame frame, WebSocketConnection connection) {
                    this.outer.onFrame(frame, connection);
                }

                override void onError(Exception t, WebSocketConnection connection) {
                    this.outer.onError(t, connection);
                }
            });

            // router().addRoute("*", path, handler( (ctx) { })); 
        }
    }

    /**
    Raw WebSocket protocol Handler
    */
    class SimpleWebSocketHandler : WebSocketHandler {
        override bool acceptUpgrade(HttpRequest request, HttpResponse response, 
            HttpOutputStream output, HttpConnection connection) {
            version(HUNT_DEBUG) {
                logInfof("The connection %s will upgrade to WebSocket connection",
                        connection.getId());
            }
            string path = request.getURI().getPath();
            WebSocketHandler handler = webSocketHandlerMap.get(path, null);
            if (handler is null) {
                response.setStatus(HttpStatus.BAD_REQUEST_400);
                try {
                    output.write(cast(byte[])("The " ~ path 
                        ~ " can not upgrade to WebSocket"));
                }catch (IOException e) {
                    logErrorf("Write http message exception", e);
                }
                return false;
            }
            else {
                return handler.acceptUpgrade(request, response, output, connection);
            }
        }

        override void onConnect(WebSocketConnection connection) {
            string path = connection.getUpgradeRequest().getURI().getPath();
            WebSocketHandler handler = webSocketHandlerMap.get(path, null);
            if (handler !is null) {
                try {
                    handler.onConnect(connection);
                } catch (Exception e) {
                    logErrorf("WebSocket connection failed: ", e.msg);
                }
            }
        }

        override void onFrame(Frame frame, WebSocketConnection connection) {
            string path = connection.getUpgradeRequest().getURI().getPath();
            WebSocketHandler handler = webSocketHandlerMap.get(path, null);
            if (handler !is null) {
                try {
                    handler.onFrame(frame, connection);
                } catch (Exception e) {
                    logErrorf("WebSocket frame handling failed: ", e.msg);
                }
            }
        }

        override void onError(Exception t, WebSocketConnection connection) {
            string path = connection.getUpgradeRequest().getURI().getPath();
            WebSocketHandler handler = webSocketHandlerMap.get(path, null);
            if (handler !is null)
                handler.onError(t, connection);
        }
    }

    // version (USE_KISS_RPC) {
    //     import kissrpc.RpcManager;

    //     public void startRpcService(T, A...)() {
    //         if (config().rpc.enabled == false)
    //             return;
    //         string ip = config().rpc.service.address;
    //         ushort port = config().rpc.service.port;
    //         int threadNum = config().rpc.service.workerThreads;
    //         RpcManager.getInstance().startService!(T, A)(ip, port, threadNum);
    //     }

    //     public void startRpcClient(T)(string ip, ushort port, int threadNum = 1) {
    //         if (config().rpc.enabled == false)
    //             return;
    //         RpcManager.getInstance().connectService!(T)(ip, port, threadNum);
    //     }
    // }

    this() {
        setDefaultLogging();

        this._dispatcher = new Dispatcher();
        setConfig(configManager().config());
    }

    __gshared static Application _app;

private:

    Address addr;
    HttpServer _server;
    Dispatcher _dispatcher;

    version(WITH_HUNT_ENTITY)
    {
        EntityManagerFactory _entityManagerFactory;
    }

    Cache _cache;
    SessionStorage _sessionStorage;
    AccessManager _accessManager;
    WebSocketPolicy _webSocketPolicy;
    WebSocketHandler[string] webSocketHandlerMap;
    Array!WebSocketBuilder webSocketBuilders; 
    MiddlewareInterface[string][string]  _groupMiddlewares;
    BreadcrumbsHandler _breadcrumbsHandler;

    version (NO_TASKPOOL) {
        // NOTHING TODO
    }
    else {
        __gshared TaskPool _tpool;
    }
}

Application app() {
    return Application.getInstance();
}

void setDefaultLogging() {
    version(HUNT_DEBUG) {} 
    else {
        LogConf logconf;
        logconf.level = hunt.logging.LogLevel.LOG_Off;
        logconf.disableConsole = true;
        logLoadConf(logconf);
    }
}

shared static this() {
    setDefaultLogging();
}
