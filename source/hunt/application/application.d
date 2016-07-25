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
public import collie.channel;
public import collie.codec.http.config;
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

public import hunt.application.middleware;

final class Application
{
	static @property app(){
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
	auto addRouter(string domain, string method, string path, DOHandler handle,
		shared RouterPipelineFactory before = null, shared RouterPipelineFactory after = null)
	{
		method = toUpper(method);
		router.addRouter(domain,method,path,handle,before,after);
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
	auto addRouter(string method, string path, DOHandler handle,
		shared RouterPipelineFactory before = null, shared RouterPipelineFactory after = null)
	{
		method = toUpper(method);
		router.addRouter(method,path,handle,before,after);
		return this;
	}
	
	/**
        Set The PipelineFactory that create the middleware list for all router rules, before  the router rule's handled execute.
    */
	auto setGlobalBeforePipelineFactory(shared RouterPipelineFactory before)
	{
		router.setGlobalBeforePipelineFactory(before);
		return this;
	}
	
	/**
        Set The PipelineFactory that create the middleware list for all router rules, after  the router rule's handled execute.
    */
	auto setGlobalAfterPipelineFactory(shared RouterPipelineFactory after)
	{
		router.setGlobalAfterPipelineFactory(after);
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
	
	
	/**
        Set The delegate that handle 404,when the router don't math the rule.
    */
	auto setNoFoundHandler(DOHandler nofound)
		in
	{
		assert(nofound !is null);
	}
	body
	{
		_404 = nofound;
		return this;
	}
	
	/// get the router.
	@property router()
	{
		return _router;
	}
	
	@property server(){return _server;}
	
	@property mainLoop(){return _mainLoop;}
	
	@property loopGroup(){return _group;}
	
	@property appConfig(){return _config;}
	
	auto setConfigPath(string path)
	{
		_config = new WebConfig(path);
		return this;
	}
	
	auto setConfig(IWebConfig conf)
	{
		_config = conf;
	}
	/**
        Start the HTTPServer server , and block current thread.
    */
	void run()
	{
		upConfig();
		auto config = _config.routerConfig();
		if(config !is null)
			setRouterConfigHelper!("__CALLACTION__",IController,HTTPRouterGroup)
				(_router,config);
		router.done();
		
		auto _db = _config.dbConfig();
		if(_db && _db.isVaild())
			initDb(_db.getUrl());
		
		_server.run();
	}
	
	
	/**
        Stop the server.
    */
	void stop()
	{
		_server.stop();
	}
	
private:
	/// math the router and start handle the middleware and handle.
	void doHandle(Request req, Response res)
	{
		RouterPipeline pipe = null;
		pipe = _router.match(req.host,req.method, req.path);
		if (pipe is null)
		{
			app._404(req, res);
		}
		else
		{
			
			scope(exit)
			{
				import core.memory;
				pipe.destroy;
				GC.free(cast(void *)pipe);
			}
			
			if(pipe.matchData().length > 0)
			{
				pipe.swapMatchData(req.materef());
			}
			pipe.handleActive(req, res);
		}
	}
	
	/// the default handle when the router rule don't match.
	void default404(Request req, Response res)
	{
		res.Header.statusCode = 404;
		res.setContext("No Found");
		res.done();
	}
	
	void upConfig()
	{
		_server.bind(_config.httpConfig.bindAddress());
		_server.setSSLConfig(_config.httpConfig.sslConfig());
		auto ts = _config.httpConfig.threadSize() - 1;
		if(ts > 0)
		{
			_group = new EventLoopGroup(ts);
			_server.group(_group);
		} 
		_server.keepAliveTimeOut(_config.httpConfig.keepAliveTimeOut());
		_server.maxBodySize(_config.httpConfig.httpMaxBodySize());
		_server.maxHeaderSize(_config.httpConfig.httpMaxHeaderSize());
		_server.headerStectionSize(_config.httpConfig.httpHeaderStectionSize());
		_server.requestBodyStectionSize(_config.httpConfig.httpRequestBodyStectionSize());
		_server.responseBodyStectionSize(_config.httpConfig.httpResponseBodyStectionSize());
		_wfactory = _config.httpConfig.webSocketFactory();
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
		_mainLoop = new EventLoop();
		_server = new HTTPServer(_mainLoop);
		_router = new HTTPRouterGroup();
		_server.setCallBack(&doHandle);
		_404 = &default404;
		_config = new WebConfig();
	}
	
	__gshared static Application _app;
private:
	HTTPRouterGroup _router;
	DOHandler _404;
	//    ServerBootstrap!HTTPPipeline _server;
	HTTPServer _server;
	EventLoop _mainLoop;
	EventLoopGroup _group;
	WebSocketFactory _wfactory;
	IWebConfig _config;
	
	shared AbstractMiddlewareFactory _middlewareFactory;
}
