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
module hunt.application.config;

import std.string;

import hunt.routing.configbase;
public import hunt.application.config.database;
public import hunt.application.config.http;

import hunt.utils.path;
import std.experimental.logger;

interface IWebConfig
{
    @property HTTPConfig httpConfig();
    @property RouterConfigBase routerConfig();
	@property DBConf dbConfig(); 
}

class WebConfig : IWebConfig
{
    this(string path)
    {
        import hunt.router.config;
        if(!endsWith(path,"/"))
            path ~= "/";
		_http = new HTTPConfig(buildPath(theExecutorPath,  path ~ "application.conf"));
		_router = new RouterConfig(buildPath(theExecutorPath,path ~ "routes.conf"));
			_db = new DBConf(buildPath(theExecutorPath,path ~ "database.conf"));
		info("application config path:", buildPath(theExecutorPath,  path ~ "application.conf") );
		info("routes config path:", buildPath(theExecutorPath,  path ~ "routes.conf") );
		info("database config path:", buildPath(theExecutorPath,  path ~ "database.conf") );
    }
    
    this()
    {
        this("config");
    }
    
    
    override @property HTTPConfig httpConfig(){return _http;}
    override @property RouterConfigBase routerConfig(){return _router;}
	override @property DBConf dbConfig(){return _db;}
private:
    HTTPConfig _http;
    RouterConfigBase _router;
	DBConf _db;
}

