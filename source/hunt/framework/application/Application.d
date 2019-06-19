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
import hunt.logging;

import hunt.io.Common;

import hunt.Exceptions;
import hunt.Functions;

import hunt.net.NetUtil;

import hunt.http.codec.http.model;
import hunt.http.codec.http.stream;
import hunt.http.codec.websocket.frame.Frame;
import hunt.http.codec.websocket.stream.AbstractWebSocketBuilder;
import hunt.http.codec.websocket.stream.WebSocketConnection;
import hunt.http.codec.websocket.stream.WebSocketPolicy;
import hunt.http.server;

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

// version(WITH_HUNT_CACHE)
// {
    public import hunt.cache;
// }

version(WITH_HUNT_ENTITY)
{
    public import hunt.entity;
}

version(WITH_HUNT_TRACE)
{
    public import hunt.trace;
}

public import hunt.event;
public import hunt.event.EventLoopGroup;

import hunt.Functions;

import std.exception;
import std.conv;
import std.file;
import std.path;
import std.parallelism;
import std.socket;
import std.stdio;
import std.string;
import std.uni;
import std.container.array;

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

                infof("using database: ", config.defaultOptions.driver);
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

    private void initCache(ApplicationConfig.CacheConf config) {
        _manger.createCache("default", config.storage, config.args, config.enableL2);
    }

    private void initSessionStorage(ApplicationConfig.SessionConf config) {
        _sessionStorage = new SessionStorage(UCache.CreateUCache(config.storage,
                config.args, false));

        _sessionStorage.setPrefix(config.prefix);
        _sessionStorage.expire = config.expire;
    }

    version(WITH_HUNT_ENTITY)
    {
        EntityManagerFactory entityManagerFactory() {
            return _entityManagerFactory;
        }
    }

    CacheManger cacheManger() {
        return _manger;
    }

    SessionStorage sessionStorage() {
        return _sessionStorage;
    }

    UCache cache() {
        return _manger.getCache("default");
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
            auto local = new EndPoint();
            local.serviceName = config.application.name;
            local.ipv4 = config.http.address;
            local.port = config.http.port;

            if(config.trace.enable && config.trace.service.host != string.init)
            {
                initIMF(config.trace.service.host , config.trace.service.port);
            }

            Tracer.localEndpoint = local;
        }
    }

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

        if (_server.getHttp2Configuration.isSecureConnectionEnabled())
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
                logDebugf("new request from: %s", c.getRemoteAddress.toString());

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

            // IO.close(r.getResponse());
            return true;
        }).badMessage((status, reason, request, response, ot, connection) {
            if (_badMessage !is null) {
                if (request.getAttachment() !is null) {
                    Request r = cast(Request) request.getAttachment();
                    _badMessage(status, reason, r);
                }
                else {
                    Request r = new Request(request, response, ot, connection, _sessionStorage);
                    request.setAttachment(r);
                    _badMessage(status, reason, r);
                }
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

    private void buildHttpServer(ApplicationConfig conf) {
        version(HUNT_DEBUG) logDebug("addr:", conf.http.address, ":", conf.http.port);

        SimpleWebSocketHandler webSocketHandler = new SimpleWebSocketHandler();
        webSocketHandler.setWebSocketPolicy(_webSocketPolicy);

        HttpConfiguration configuration = new HttpConfiguration();

        _server = new HttpServer(conf.http.address, conf.http.port,
                configuration, buildHttpHandlerAdapter(), webSocketHandler);
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
                warningf("It's better to make the number of worker thread greater than %d", minThreadCount);
                // conf.http.workerThreads = minThreadCount;
            }
            _tpool = new TaskPool(conf.http.workerThreads);
            _tpool.isDaemon = true;
        }

        buildHttpServer(conf);

        //if(conf.webSocketFactory)
        //    _wfactory = conf.webSocketFactory;

        version(HUNT_DEBUG) logDebug(conf.route.groups);

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
                        connection.getSessionId());
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

        _manger = new CacheManger();

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

    CacheManger _manger;
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
