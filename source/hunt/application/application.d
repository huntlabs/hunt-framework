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

import collie.codec.http.server.websocket;
import collie.buffer;
import collie.codec.http.server;
import collie.codec.http;
import collie.bootstrap.serversslconfig;

public import collie.socket.eventloop;
public import collie.socket.eventloopgroup;

public import std.socket;
public import std.experimental.logger;
public import std.file;

import std.uni;
import std.path;
import std.parallelism;
import std.exception;

import hunt.router;
public import hunt.http;
public import hunt.view;
public import hunt.i18n;
public import hunt.utils.path;
public import hunt.application.config;
public import hunt.application.middleware;

abstract class WebSocketFactory
{
	IWebSocket newWebSocket(const HTTPMessage header);
}


final class Application
{
	alias HandleDelegate = void delegate(Request);
	alias HandleFunction = void function(Request);

	static @property getInstance()
	{
		if(_app is null)
		{
			_app = new Application();
		}
		return _app;
	}

	Address binded(){return addr;}
	
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
	auto addRoute(T)(string domain, string method,string path,T handle)
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

	///启用国际化
	auto enableLocale(string resPath = buildPath(theExecutorPath, "./resources/lang"), string defaultLocale = "zh-cn")
	{
		auto i18n = I18n.instance();
		i18n.loadLangResources(resPath);
		i18n.defaultLocale = defaultLocale;

		return this;
	}

	void setWebSocketFactory(WebSocketFactory webfactory)
	{
		_wfactory = webfactory;
	}

	version(NO_TASKPOOL){} else {
		@property TaskPool taskPool(){return _tpool;}
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

	void setCreateBuffer(CreatorBuffer cbuffer)
	{
		if(cbuffer)
			_cbuffer = cbuffer;
	}
	private void initDb(AppConfig.DBConfig conf)
	{
		version (WITH_ENTITY) {
			trace("conf..", conf);
			if(conf.url == "")return;
			import std.string;
			import hunt.utils.url;
			import std.conv;
			import hunt.application.model;
			URL url = conf.url.parseURL();
			url.queryArr["user"] = url.user;
			url.queryArr["password"] = url.pass;
			trace("driver:", url.scheme, " hosturl ", url.toString()," user:",url.user, " pwd:", url.pass, "queryarr", url.queryArr);
			initDB(url.scheme, url.scheme~"://" ~url.host ~":" ~to!string(url.port) ~url.path~"?"~url.query,url.queryArr);
		}
	}

	/**
        Start the HTTPServer server , and block current thread.
    */
	void run()
	{
		setLogConfig(Config.app.log);
		upConfig(Config.app);
		upRouterConfig();
		initDb(Config.app.database);
		import std.stdio;
		writeln("please open http://",addr.toString,"/");
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
	RequestHandler newHandler(RequestHandler handler,HTTPMessage msg){
		if(!msg.upgraded)
		{
			return new Request(_cbuffer,&handleRequest,_maxBodySize);
		}
		else if(_wfactory)
		{
			return _wfactory.newWebSocket(msg);
		}

		return null;
	}

	Buffer defaultBuffer(HTTPMessage msg) nothrow
	{
		try{
			import std.experimental.allocator.gc_allocator;
			import collie.buffer.ubytebuffer;
			if(msg.chunked == false){
				string contign = msg.getHeaders.getSingleOrEmpty(HTTPHeaderCode.CONTENT_LENGTH);
				if(contign.length > 0){
					import std.conv;
					uint len = 0;
					collectException(to!(uint)(contign),len);
					if(len > _maxBodySize)
						return null;
				}
			}
			return new UbyteBuffer!ubyte();
		} catch(Exception e){
			showException(e);
			return null;
		}
	}

	void handleRequest(Request req) nothrow
	{
		version(NO_TASKPOOL)
		{
			auto e = collectException(doHandleReqest(req));
		}
		else
		{
			auto e = collectException(_tpool.put(task!doHandleReqest(req)));
		}

		if(e)
			showException(e);
	}

private:
	void upConfig(AppConfig conf)
	{
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

		HTTPServerOptions option = new HTTPServerOptions();
		option.maxHeaderSize = conf.http.maxHeaderSize;
		//option.listenBacklog = conf.http.listenBacklog;

		version(NO_TASKPOOL)
		{
			option.threads = conf.http.ioThreads + conf.http.workerThreads;
		}
		else
		{
			option.threads = conf.http.ioThreads;
		}

		option.timeOut = conf.http.keepAliveTimeOut;
		option.handlerFactories.insertBack(&newHandler);
		_server = new HttpServer(option);
		addr = parseAddress(conf.http.address,conf.http.port);
		// foreach(Address addr; conf.bindAddress)
		// {
			HTTPServerOptions.IPConfig ipconf;
			ipconf.address = addr;
			//ipconf.fastOpenQueueSize = conf.fastOpenQueueSize;
			//ipconf.enableTCPFastOpen = (conf.fastOpenQueueSize > 0);

			_server.addBind(ipconf);
		// }

		//if(conf.webSocketFactory)
		//	_wfactory = conf.webSocketFactory;
	}

	void setLogConfig(ref AppConfig.LogConfig conf)
	{
		switch(conf.level)
		{
			case "all":
				globalLogLevel = LogLevel.all;
				break;
			case "critical":
				globalLogLevel = LogLevel.critical;
				break;
			case "error":
				globalLogLevel = LogLevel.error;
				break;
			case "fatal":
				globalLogLevel = LogLevel.fatal;
				break;
			case "info":
				globalLogLevel = LogLevel.info;
				break;
			case "trace":
				globalLogLevel = LogLevel.trace;
				break;
			case "warning":
				globalLogLevel = LogLevel.warning;
				break;
			case "off":
			default:
				globalLogLevel = LogLevel.off;
				break;
		}
		
		if(conf.file.length > 0 && conf.path.length > 0)
		{
			import std.path;
			string file = buildPath(conf.path,conf.file);
			sharedLog = new FileLogger(file);
		}
	}

	void upRouterConfig()
	{
		auto router = Config.router;
		if(router)

			setRouterConfigHelper(router);
		defaultRouter.done();
	}

	this()
	{
		_cbuffer = &defaultBuffer;
	}
	
	__gshared static Application _app;
private:
	Address addr;
	HttpServer _server;
	WebSocketFactory _wfactory;
	uint _maxBodySize;
	CreatorBuffer _cbuffer;

	version(NO_TASKPOOL)
	{
		// NOTHING TODO
	}
	else
	{
		__gshared TaskPool _tpool;
	}
}

import collie.utils.exception;
import hunt.application.controller;

void doHandleReqest(Request req) nothrow
{
	try
	{
		MachData data = defaultRouter.match(req.header(HTTPHeaderCode.HOST), req.method, req.path);

		if(data.macth)
		{
			foreach(key, value; data.mate)
			{
				req.addMate(key,value);
			}

			switch(data.macth.type)
			{
				case RouterHandlerType.Delegate:
					data.macth.dgate()(req);
					return;
				case RouterHandlerType.Function:
					data.macth.func()(req);
					return;
				default:
					break;
			}
		}

		Response rep = req.createResponse();
		if(rep)
		{
			rep.setHttpStatusCode(404);
			rep.setContext("<h1>NOT Found<h1>");
			rep.connectionClose();
			rep.done();
		}

	}
	catch (CreateResponseException e)
	{
		showException(e);
	}
	catch (Exception e)
	{
		showException(e);

		Response rep;
		collectException(req.createResponse, rep);

		if(rep)
		{
			collectException((){
					rep.setHttpStatusCode(502);
					rep.setContext(e.toString());
					rep.connectionClose();
					rep.done();
				}());
		}
	}  catch (Error e){
		import std.stdio;
		collectException({error(e.toString); writeln(e.toString());}());
		import core.stdc.stdlib;
		exit(-1);
	}
}
