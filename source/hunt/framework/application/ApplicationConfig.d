﻿/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.application.ApplicationConfig;

import std.exception;
import std.format;
import std.parallelism : totalCPUs;
import std.process;
import std.socket : Address, parseAddress;
import std.string;

import hunt.cache.CacheOptions;
import hunt.http.codec.http.model.MultipartConfig;
import hunt.logging;
import hunt.framework.Init;
import hunt.redis.RedisPoolOptions;
import hunt.util.Configuration;


@Configuration("hunt")
final class ApplicationConfig
{
    struct ApplicationConf
    {
        string name = "Hunt Application";
        string baseUrl = "http://localhost:8080";
        string defaultCookieDomain = "localhost";
        string defaultLanguage = "en-US";
        string languages = "zh-CN,en-US";
        string secret = "CD6CABB1123C86EDAD9";
        string encoding = "utf-8";
        int staticFileCacheMinutes = 30;
    }

    struct CookieConf
    {
        string domain = "";
        string path = "/";
        int expires = 3600;
        bool secure = false;
        bool httpOnly = true;
    }

    struct SessionConf
    {
        string storage = "memory";
        string prefix = "huntsession_";
        string args = "/tmp";
        uint expire = 3600; // in seconds
    }

    struct HttpConf
    {
        string address = "0.0.0.0";
        string path = "wwwroot/";
        ushort port = 8080;
        uint workerThreads = 4;
        uint ioThreads = 2;
        size_t keepAliveTimeOut = 30;
        size_t maxHeaderSize = 60 * 1024;
        int cacheControl;
        bool enableCors = false; // CORS support
        string allowOrigin = "*";
        string allowMethods = "*";
        string allowHeaders = "*";
        // DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type
    }

    struct HttpsConf
    {
        bool enabled = false;
        string protocol;
        string keyStore;
        string keyStoreType;
        string keyStorePassword;
    }

    struct RouteConf
    {
        string groups;
    }

    struct LoggingConfig
    {
        string level = "all";
        string path;
        string file = "";
        bool disableConsole = false;
        string maxSize = "8M";
        uint maxNum = 8;
    }

    struct MemcacheConf
    {
        bool enabled = false;
        string servers;
    }

    struct RedisConf
    {
        bool enabled = false;
        string host = "127.0.0.1";
        string password = "";
        ushort database = 0;
        ushort port = 6379;
        uint timeout = 0;
        RedisPoolConf pool;
        ClusterOption cluster;
    }

    struct ClusterOption {
        string[] nodes;
        bool enabled;
    }

    struct RedisPoolConf {
        bool enabled = false;        
        bool blockOnExhausted = true;
        uint idleTimeout = 30000; // millisecond
        uint maxPoolSize = 20;
        uint minPoolSize = 5;
        uint maxLifetime = 2000000;
        uint connectionTimeout = 15000;
        int waitTimeout = 15000; // -1: forever
        uint maxConnection = 20;
        uint minConnection = 5; 
    }

    struct UploadConf
    {
        string path = "/tmp";
        long maxSize = 4 * 1024 * 1024;
    }

    struct MailSmtpConf
    {
        string host;
        string channel;
        ushort port;
        string protocol;
        string user;
        string password;
    }

    struct MailConf
    {
        MailSmtpConf smtp;
    }

    struct DbPoolConf
    {
        string name = "";
        int minIdle = 5;
        int idleTimeout = 30000;
        int maxPoolSize = 20;
        int minPoolSize = 5;
        int maxLifetime = 2000000;
        int connectionTimeout = 30000;
        int maxConnection = 20;
        int minConnection = 5;
    }

    struct DBConfig
    {
        string url()
        {
            string s = format("%s://%s:%s@%s:%d/%s?prefix=%s&charset=%s",
                    driver, username, password, host, port, database, prefix, charset);
            return s;
        }

        string driver = "postgresql";
        string host = "localhost";
        ushort port = 5432;
        string database = "test";
        string username = "root";
        string password = "";
        string charset = "utf8";
        string prefix = "";
        bool enabled = false;
    }

    struct DatabaseConf
    {
        @Value("default")
        DBConfig defaultOptions;

        DbPoolConf pool;
    }

    struct DateConf
    {
        string format;
        string timeZone;
    }

    struct CornConf
    {
        string noon;
    }

    struct ServiceConf
    {
        string address = "127.0.0.1";
        ushort port = 8080;
        int workerThreads = 1;
        string password;
    }

    struct RpcConf
    {
        bool enabled = true;
        ServiceConf service;
    }

    struct View
    {
        string path = "./resources/views/";
        string ext = ".html";
        uint arrayDepth = 3;
        bool cacheEnabled = true;
    }

    struct TraceConf
    {
        bool enable = false;
        bool b3Required = true;
        TraceService service;
        string zipkin = "http://127.0.0.1:9411/api/v2/spans";
    }

    struct TraceService
    {
        string host;
        ushort port;
    }

    DatabaseConf database;
    ApplicationConf application;
    CookieConf cookie;
    SessionConf session;
    CacheOptions cache;
    HttpConf http;
    HttpsConf https;
    RouteConf route;
    MemcacheConf memcache;
    RedisConf redis;
    LoggingConfig logging;
    UploadConf upload;
    CornConf cron;
    DateConf date;
    MailConf mail;
    RpcConf rpc;
    View view;
    TraceConf trace;

    MultipartConfig multipartConfig()
    {
        if(_multipartConfig is null)
        {
            string path = buildPath(DEFAULT_TEMP_PATH, upload.path);
            if(!path.exists())
            {
                // for Exception now?
                path.mkdirRecurse();
            }
            _multipartConfig = new MultipartConfig(path, upload.maxSize, upload.maxSize, 50); 
        }
        return _multipartConfig;
    }

    private MultipartConfig _multipartConfig;

    this()
    {
        http.workerThreads = totalCPUs * 4;
        upload.path = DEFAULT_TEMP_PATH;
        view.path = DEFAULT_TEMPLATE_PATH;
    }
}

import core.sync.rwmutex;

import std.array;
import std.file;
import std.path;
import std.exception : basicExceptionCtors;

/**
*/
class ConfigNotFoundException : Exception
{
    mixin basicExceptionCtors;
}

/**
*/
class ConfigManager
{
    ApplicationConfig config(string section="", string fileName = "application.conf")
    {
        if (!_appConfig) {
                
            if(fileName == "application.conf") {
                string huntEnv = environment.get("HUNT_ENV", "");
                version(HUNT_DEBUG) tracef("huntEnv=%s", huntEnv);
                if(!huntEnv.empty) {
                    fileName = "application." ~ huntEnv ~ ".conf";
                }
            }
            
            if(fileName.empty)
                fileName = "application.conf";

            setAppSection(section, fileName);
        }

        return _appConfig;
    }

    @property string path()
    {
        return this._path;
    }

    void setConfigPath(string path)
    {
        if (path.empty)
            return;

        if (path[$ - 1] == '/')
            this._path = path;
        else
            this._path = path ~ "/";
    }

    void setAppSection(string sec, string fileName = "application.conf")
    {
        string fullName = buildPath(path, fileName);
        if (exists(fullName))
        {
            infof("using the config file: %s", fullName);
            _defaultBuilder = new ConfigBuilder(fullName, sec);
            _appConfig = _defaultBuilder.build!(ApplicationConfig, "hunt")();
            addConfig("hunt", _defaultBuilder);
        }
        else
        {
            warningf("Configure file does not exist: %s", fullName);
            _defaultBuilder = new ConfigBuilder();
            info("Using default settings.");
            _appConfig = new ApplicationConfig();
        }

    }

    ConfigBuilder defaultBuilder() {
        return _defaultBuilder;
    }
    private ConfigBuilder _defaultBuilder;

    ConfigBuilder config(string key)
    {
        import std.format;

        ConfigBuilder v = null;
        synchronized (_mutex.reader)
        {
            v = _conf.get(key, null);
        }

        enforce!ConfigNotFoundException(v, format(" %s is not created! ", key));

        return v;
    }

    void addConfig(string key, ConfigBuilder conf)
    {
        _mutex.writer.lock();
        scope (exit)
            _mutex.writer.unlock();
        _conf[key] = conf;
    }

    auto opDispatch(string s)()
    {
        return config(s);
    }

private:
    this()
    {
        _mutex = new ReadWriteMutex();
        _path = DEFAULT_CONFIG_PATH;
    }

    ~this()
    {
        _mutex.destroy;
    }

    ApplicationConfig _appConfig;
    ConfigBuilder[string] _conf;
    string _path;
    ReadWriteMutex _mutex;
}

ConfigManager configManager()
{
    return _manger;
}

shared static this()
{
    _manger = new ConfigManager();
}

private:
__gshared ConfigManager _manger;
