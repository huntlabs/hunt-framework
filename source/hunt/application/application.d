/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */

module hunt.application.application;

import collie.bootstrap.serversslconfig;
public import collie.socket.eventloop;
public import collie.socket.eventloopgroup;
import collie.codec.http.server;
import collie.codec.http;

public import std.socket;
public import std.experimental.logger;
import std.uni;

import hunt.router;
public import hunt.http;
public import hunt.view;
public import hunt.i18n;
public import std.file;
public import hunt.utils.path;
public import hunt.application.config;

public import hunt.application.middleware;
import collie.codec.http.server.websocket;

abstract class WebSocketFactory
{
	IWebSocket newWebSocket(const HTTPMessage header);
}


final class Application
{
	alias HandleDelegate = void delegate(Request);
	alias HandleFunction = void function(Request);

	static @property getInstance(){
		if(_app is null)
		{
			_app = new Application();
		}
		return _app;
	}
	
	/**
        Add a Router rule
        Params:
            domain =  the rule's domain group.
            method =  the HTTP method. 
            path   =  the request path.
            handle =  the delegate that handle the request.
            before =  The PipelineFactory that create the middleware list for the router rules, before  the router rule's handled execute.
            after  =  The PipelineFactory that create the middleware list for the router rules, after  the router rule's handled execute.
    */
	auto addRoute(T)(string domain, string method,T handle)
		if(is(T == HandleDelegate) || is(T == HandleFunction))
	{
		method = toUpper(method);
		defaultRouter.addRoute(domain,method,path,handle);
		return this;
	}
	
	/**
        Add a Router rule
        Params:
            method =  the HTTP method. 
            path   =  the request path.
            handle =  the delegate that handle the request.
            before =  The PipelineFactory that create the middleware list for the router rules, before  the router rule's handled execute.
            after  =  The PipelineFactory that create the middleware list for the router rules, after  the router rule's handled execute.
    */
	auto addRoute(T)(string method, string path,T handle)
		if(is(T == HandleDelegate) || is(T == HandleFunction))
	{
		method = toUpper(method);
		defaultRouter.addRoute(method,path,handle);
		return this;
	}
	///
	auto setMiddlewareFactory(shared AbstractMiddlewareFactory mfactory)
	{
		_middlewareFactory = mfactory;
		return this;
	}

	@property auto middlewareFactory()
	{
		return _middlewareFactory;
	}

	///启用国际化
	auto enableLocale(string resPath = buildPath(theExecutorPath, "./resources/lang"), string defaultLocale = "zh-cn")
	{
		auto i18n = I18n.instance();
		i18n.loadLangResources(resPath);
		i18n.defaultLocale = defaultLocale;
		return this;
	}

	
	/// get the router.
	@property router()
	{
		return defaultRouter;
	}
	
	@property server(){return _server;}
	
	@property mainLoop(){return _server.eventLoop;}
	
	@property loopGroup(){return _server.group;}
	
	@property appConfig(){return Config.app;}

	/**
        Start the HTTPServer server , and block current thread.
    */
	void run()
	{
		upConfig();
		/*auto config = Config.router;
		if(config !is null)
			setRouterConfigHelper!("__CALLACTION__",IController,HTTPRouterGroup)
				(_router,config);
		router.done();*/

		_server.start();
	}
	
	
	/**
        Stop the server.
    */
	void stop()
	{
		_server.stop();
	}
	
private:
	void upConfig()
	{
		_server.bind(Config.app.server.bindAddress() );
		//_server.setSSLConfig(_config.httpConfig.sslConfig());
		uint ts = Config.app.server.workerThreads - 1;
		
		if(ts > 0)
		{
			_group = new EventLoopGroup(ts);
			_server.group(_group);
		}
		
		_server.keepAliveTimeOut(Config.app.http.keepAliveTimeOut);
		_server.maxBodySize(Config.app.http.maxBodySzie);
		_server.maxHeaderSize(Config.app.http.maxHeaderSize);
		_server.headerStectionSize(Config.app.http.headerSection);
		_server.requestBodyStectionSize(Config.app.http.requestSection);
		_server.responseBodyStectionSize(Config.app.http.responseSection);
		_wfactory = Config.app.http.webSocketFactory;
		
		if(_wfactory is null)
		{
			_server.setWebsocketFactory(null);  
		}
		else
		{
			_server.setWebsocketFactory(&_wfactory.newWebSocket);
		}
	}
	
	/// default Constructor
	this()
	{

	}
	
	__gshared static Application _app;
private:
	//    ServerBootstrap!HTTPPipeline _server;
	HttpServer _server;
	WebSocketFactory _wfactory;
	
	shared AbstractMiddlewareFactory _middlewareFactory;
}
