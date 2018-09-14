/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Website: www.huntframework.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.application.application;

import hunt.container.ByteBuffer;
// import collie.codec.http.server;
// import collie.codec.http;
// import collie.bootstrap.serversslconfig;
// import collie.utils.exception;

import hunt.cache;
import hunt.container;
import hunt.http.codec.http.model;
import hunt.http.codec.http.stream;
import hunt.http.server;
import hunt.io.common;
import hunt.logging;
import hunt.util.exception;
import hunt.util.functional;
import hunt.http.codec.websocket.frame.Frame;
import hunt.http.codec.websocket.stream.WebSocketConnection;
import hunt.http.codec.websocket.stream.WebSocketPolicy;

public import hunt.event;
public import hunt.event.EventLoopGroup;

public import std.socket;
public import std.file;

import std.string;
import std.conv;
import std.stdio;
import std.uni;
import std.path;
import std.parallelism;
import std.exception;

import hunt.framework.init;
import hunt.framework.routing;
import hunt.framework.application.dispatcher;
import hunt.framework.security.acl.Manager;

public import hunt.framework.http;
public import hunt.framework.i18n;
public import hunt.framework.application.config;
public import hunt.framework.application.middleware;
public import hunt.framework.security.acl.Identity;

public import hunt.entity;

import hunt.util.exception;


final class Application
{
    static @property Application getInstance()
    {
        if(_app is null)
        {
            _app = new Application();
        }

        return _app;
    }

    Address binded(){return addr;}

    // enable i18n
    Application enableLocale(string resPath = DEFAULT_LANGUAGE_PATH, string defaultLocale = "en-us")
    {
        I18n i18n = I18n.instance();

        i18n.loadLangResources(resPath);
        i18n.defaultLocale = defaultLocale;

        return this;
    }

    // void setWebSocketFactory(WebSocketFactory webfactory)
    // {
    //     _wfactory = webfactory;
    // }

    version(NO_TASKPOOL){} else {
        @property TaskPool taskPool(){return _tpool;}
    }

    /// get the router.
    @property router()
    {
        return this._dispatcher.router();
    }

    @property server(){return _server;}

    // @property mainLoop(){return _server.eventLoop;}

    // @property loopGroup(){return _server.group;}

    @property AppConfig config(){return Config.app;}

    // void setCreateBuffer(CreatorBuffer cbuffer)
    // {
    //     if(cbuffer)
    //         _cbuffer = cbuffer;
    // }

    private void initDatabase(AppConfig.DatabaseConf config)
    {
        if(config.defaultOptions.url.empty)
        {
            logWarning("No database configured!");
        }
        else
        {
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

            _entityManagerFactory = Persistence.createEntityManagerFactory("default", option);
            
        }
    }

    private void initCache(AppConfig.CacheConf config)
    {
		_manger.createCache("default" , config.storage , config.args , config.enableL2);
	}
    
    private void initSessionStorage(AppConfig.SessionConf config)
    {
		_sessionStorage = new SessionStorage(UCache.CreateUCache(config.storage , config.args , false));
      
		_sessionStorage.setPrefix(config.prefix);
        _sessionStorage.setExpire(config.expire);

		// writeln(" initSessionStorage " ,_sessionStorage);
    }

    EntityManagerFactory entityManagerFactory()
    {
        return _entityManagerFactory;
    }

	CacheManger cacheManger()
	{
		return _manger;
	}
	
	SessionStorage sessionStorage()
	{
		// writeln(" getSessionStorage " , _sessionStorage);
		return _sessionStorage;
	}
	
	UCache cache()
	{
		return  _manger.getCache("default");

	}

	AccessManager accessManager()
	{
		return _accessManager;
	}

    /**
      Start the HTTPServer server , and block current thread.
     */
    void run()
	{
		start();
	}

	/*
	void run(Address addr)
	{
		Config.app.http.address = addr.toAddrString;
		Config.app.http.port = addr.toPortString.to!ushort;
		setConfig(Config.app);
		start();
	}*/

	void setConfig(AppConfig config)
	{
		setLogConfig(config.logging);
		upConfig(config);
		//setRedis(config.redis);
		//setMemcache(config.memcache);

        if(config.database.defaultOptions.enabled)
            initDatabase(config.database);
		initCache(config.cache);
		initSessionStorage(config.session);
	}

	void start()
	{
		writeln("Try to browse http://",addr.toString());
		_server.start();
	}

    /**
      Stop the server.
     */
    void stop()
    {
        _server.stop();
    }

    Application registerWebSocket(string uri, WebSocketHandler webSocketHandler) {
        webSocketHandlerMap[uri] = webSocketHandler;
        return this;
    }

    Application webSocketPolicy(WebSocketPolicy w) {
        this._webSocketPolicy = w;
        return this;
    }
    
    // RequestHandler newHandler(RequestHandler, HTTPMessage msg){
    //     if(!msg.upgraded)
    //     {
    //         return new Request(_cbuffer,&handleRequest,_maxBodySize);
    //     }
    //     else if(_wfactory)
    //     {
    //         return _wfactory.newWebSocket(msg);
    //     }

    //     return null;
    // }

    // Buffer defaultBuffer(HTTPMessage msg) nothrow
    // {
    //     try{
    //         import std.experimental.allocator.gc_allocator;
    //         import hunt.container.ByteBuffer;
    //         if(msg.chunked == false)
    //         {
    //             string contign = msg.getHeaders.getSingleOrEmpty(HttpHeader.CONTENT_LENGTH);
    //             if(contign.length > 0)
    //             {
    //                 import std.conv;
    //                 uint len = 0;
    //                 collectException(to!(uint)(contign),len);
    //                 if(len > _maxBodySize)
    //                     return null;
    //             }
    //         }

    //         return new ByteBuffer!(GCAllocator)();
    //     }
    //     catch(Exception e)
    //     {
    //         showException(e);
    //         return null;
    //     }
    // }

    private void handleRequest(Request req) nothrow
    {
        this._dispatcher.dispatch(req);
    }

    private Action1!Request _headerComplete;
    private Action3!(int, string, Request) _badMessage;
    private Action1!Request _earlyEof;
    // private Action1!HttpConnection _acceptConnection;
    private Action2!(Request, HttpServerConnection) tunnel;

    private ServerHttpHandlerAdapter buildHttpHandlerAdapter() {
        ServerHttpHandlerAdapter adapter = new ServerHttpHandlerAdapter();
        adapter.acceptConnection((HttpConnection c) {

            }).acceptHttpTunnelConnection((request, response, ot, connection) {
                Request r = new Request(request, response, ot, cast(HttpConnection)connection);
                request.setAttachment(r);
                if (tunnel !is null) {
                    tunnel(r, connection);
                }
                return true;
            }).headerComplete((request, response, ot, connection) {
                Request r = new Request(request, response, ot, connection);
                request.setAttachment(r);
                if (_headerComplete != null) {
                    _headerComplete(r);
                }
                // requestMeter.mark();
                return false;
            }).content((buffer, request, response, ot, connection) {
                Request r = cast(Request) request.getAttachment();
                if (r.content !is null) {
                    r.content(buffer);
                } else {
                    r.requestBody.add(buffer);
                }
                return false;
            }).contentComplete((request, response, ot, connection)  {
                Request r = cast(Request) request.getAttachment();
                if (r.contentComplete !is null) {
                    r.contentComplete(r);
                }

                return false;
            }).messageComplete((request, response, ot, connection)  {
                Request r = cast(Request) request.getAttachment();
                if (r.messageComplete != null) {
                    r.messageComplete(r);
                }

                handleRequest(r);

                // IO.close(r.getResponse());
                return true;
            }).badMessage((status, reason, request, response, ot, connection)  {
                if (_badMessage !is null) {
                    if (request.getAttachment() !is null) {
                        Request r = cast(Request) request.getAttachment();
                        _badMessage(status, reason, r);
                    } else {
                        Request r = new Request(request, response, ot, connection);
                        request.setAttachment(r);
                        _badMessage(status, reason, r);
                    }
                }
            }).earlyEOF((request, response, ot, connection)  {
                if (_earlyEof != null) {
                    if (request.getAttachment() !is null) {
                        Request r = cast(Request) request.getAttachment();
                        _earlyEof(r);
                    } else {
                        Request r = new Request(request, response, ot, connection);
                        request.setAttachment(r);
                        _earlyEof(r);
                    }
                }
            });
        return adapter;
    }

    private void buildHttpServer(AppConfig conf) {
        logDebug("addr:",conf.http.address, ":", conf.http.port);

        SimpleWebSocketHandler webSocketHandler = new SimpleWebSocketHandler();
        webSocketHandler.setWebSocketPolicy(_webSocketPolicy);

        Http2Configuration configuration = new Http2Configuration();

        _server = new HttpServer(conf.http.address, conf.http.port, configuration, 
            buildHttpHandlerAdapter(), webSocketHandler);
        // HTTPServerOptions option = new HTTPServerOptions();
        // option.maxHeaderSize = conf.http.maxHeaderSize;
        // //option.listenBacklog = conf.http.listenBacklog;

        // version(NO_TASKPOOL)
        // {
        //     option.threads = conf.http.ioThreads + conf.http.workerThreads;
        // }
        // else
        // {
        //     option.threads = conf.http.ioThreads;
        // }

        // option.timeOut = conf.http.keepAliveTimeOut;
        // option.handlerFactories ~= (&newHandler);

        // _server = new HttpServer(option);
        // HTTPServerOptions.IPConfig ipconf;
        // ipconf.address = addr;

        // _server.addBind(ipconf);
    }


    private:
    void upConfig(AppConfig conf)
    {
        addr = parseAddress(conf.http.address,conf.http.port);
        
        _maxBodySize = conf.upload.maxSize;
        version(NO_TASKPOOL)
        {
            // NOTHING
        }
        else
        {
            _tpool = new TaskPool(conf.http.workerThreads);
            _tpool.isDaemon = true;
        }

        buildHttpServer(conf);

        //if(conf.webSocketFactory)
        //    _wfactory = conf.webSocketFactory;

       logDebug(conf.route.groups);

        version(NO_TASKPOOL)
        {
        }
        else
        {
            this._dispatcher.setWorkers(_tpool);
        }
        // init dispatcer and routes
        if (conf.route.groups)
        {
            import std.array : split;
            import std.string : strip;

            string[] groupConfig;

            foreach (v; split(conf.route.groups, ','))
            {
                groupConfig = split(v, ":");

                if (groupConfig.length == 3 || groupConfig.length == 4)
                {
                    string value = groupConfig[2];

                    if (groupConfig.length == 4)
                    {
                        if (std.conv.to!int(groupConfig[3]) > 0)
                        {
                            value ~= ":"~groupConfig[3];
                        }
                    }

                    this._dispatcher.addRouteGroup(strip(groupConfig[0]), strip(groupConfig[1]), strip(value));

                    continue;
                }

                logWarningf("Group config format error ( %s ).", v);
            }
        }

        this._dispatcher.loadRouteGroups();
    }

    void setLogConfig(ref AppConfig.LoggingConfig conf)
    {
       	hunt.logging.LogLevel level = hunt.logging.LogLevel.LOG_DEBUG;

        import std.string : toLower;

        switch(toLower(conf.level))
        {
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

		LogConf logconf;
		logconf.level = level;
		logconf.disableConsole = conf.disableConsole;

        if(!conf.file.empty)
		    logconf.fileName = buildPath(conf.path, conf.file);

		logconf.maxSize = conf.maxSize;
		logconf.maxNum = conf.maxNum;

		logLoadConf(logconf);

    }

    class SimpleWebSocketHandler : WebSocketHandler
    {
           override
        bool acceptUpgrade(MetaData.Request request, 
                MetaData.Response response,
                HttpOutputStream output,
                HttpConnection connection) {
            logInfo("The connection %s will upgrade to WebSocket connection", connection.getSessionId());
            WebSocketHandler handler = webSocketHandlerMap.get(request.getURI().getPath(), null);
            if (handler is null) {
                response.setStatus(HttpStatus.BAD_REQUEST_400);
                try {
                    output.write(cast(byte[])("The " ~ request.getURI().getPath() ~ " can not upgrade to WebSocket"));
                } catch (IOException e) {
                    logErrorf("Write http message exception", e);
                }
                return false;
            } else {
                return handler.acceptUpgrade(request, response, output, connection);
            }
        }

        override
        void onConnect(WebSocketConnection connection) {
            string path = connection.getUpgradeRequest().getURI().getPath();
            WebSocketHandler handler = webSocketHandlerMap.get(path, null);
            if(handler !is null)
                handler.onConnect(connection);
        }

        override
        void onFrame(Frame frame, WebSocketConnection connection) {
            string path = connection.getUpgradeRequest().getURI().getPath();
            WebSocketHandler handler = webSocketHandlerMap.get(path, null);
            if(handler !is null)
                handler.onFrame(frame, connection);
        }

        override
        void onError(Exception t, WebSocketConnection connection) {
            string path = connection.getUpgradeRequest().getURI().getPath();
            WebSocketHandler handler = webSocketHandlerMap.get(path, null);
            if(handler !is null)
                handler.onError(t, connection);
        }
    }


    version(USE_KISS_RPC) {
        import kissrpc.RpcManager;
        public void startRpcService(T,A...)() {
            if (Config.app.rpc.enabled == false)
                return;
            string ip = Config.app.rpc.service.address;
            ushort port = Config.app.rpc.service.port;
            int threadNum = Config.app.rpc.service.workerThreads;
            RpcManager.getInstance().startService!(T,A)(ip, port, threadNum);
        }
        public void startRpcClient(T)(string ip, ushort port, int threadNum = 1) {
            if (Config.app.rpc.enabled == false)
                return;
            RpcManager.getInstance().connectService!(T)(ip, port, threadNum);
        }
    }

    this()
    {
        // _cbuffer = &defaultBuffer;
		_accessManager = new AccessManager();
		_manger = new CacheManger();

        this._dispatcher = new Dispatcher();
		setConfig(Config.app);
    }

    __gshared static Application _app;

    private:
    Address addr;
    HttpServer _server;
    // WebSocketFactory _wfactory;
    uint _maxBodySize;
    // CreatorBuffer _cbuffer;
    Dispatcher _dispatcher;
    EntityManagerFactory _entityManagerFactory;
    CacheManger _manger;
	SessionStorage _sessionStorage;
	AccessManager  _accessManager;
    WebSocketPolicy _webSocketPolicy;
    WebSocketHandler[string] webSocketHandlerMap;

    version(NO_TASKPOOL)
    {
        // NOTHING TODO
    }
    else
    {
        __gshared TaskPool _tpool;
    }
}

Application app()
{
    return Application.getInstance();
}
