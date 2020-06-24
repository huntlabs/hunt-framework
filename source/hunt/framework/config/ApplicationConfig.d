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

module hunt.framework.config.ApplicationConfig;

import hunt.framework.Init;

import std.exception;
import std.format;
import std.parallelism : totalCPUs;
import std.process;
import std.socket : Address, parseAddress;
import std.string;

import hunt.http.MultipartOptions;
import hunt.logging.ConsoleLogger;
import hunt.util.Configuration;

// 
enum ENV_APP_NAME = "APP_NAME";
enum ENV_APP_VERSION = "APP_VERSION";
enum ENV_APP_ENV = "APP_ENV";
enum ENV_APP_LANG = "APP_LANG";
enum ENV_APP_KEY = "APP_KEY";
enum ENV_APP_BASE_PATH = "APP_BASE_PATH";
enum ENV_CONFIG_BASE_PATH = "CONFIG_BASE_PATH";


// @Configuration("hunt")
@ConfigurationFile("application")
class ApplicationConfig {
    struct ApplicationConf {
        string name = "Hunt Application";
        string baseUrl = "http://localhost:8080";
        string defaultCookieDomain = "localhost";
        string defaultLanguage = "en-US";
        string languages = "zh-CN,en-US";
        string secret = "CD6CABB1123C86EDAD9";
        string encoding = "utf-8";
        int staticFileCacheMinutes = 30;
        string langLocation = "./translations";
    }

    struct AuthConf {
        string loginUrl = "/";
        string successUrl = "/";
        string unauthorizedUrl = "/";

        string basicRealm = "Secure Area";
    }

    /** Config for static files */
    struct StaticFilesConf {
        bool enabled = true;
        // default root path
        string location = DEFAULT_STATIC_FILES_LACATION;
        bool canList = true;
        int cacheTime = 30;
    }

    
    struct CacheConf {
        string adapter = "memory";
        string prefix = "";

        bool useSecondLevelCache = false;
        uint maxEntriesLocalHeap = 10000;
        bool eternal = false;
        uint timeToIdleSeconds = 3600;
        uint timeToLiveSeconds = 10;
        bool overflowToDisk = true;
        bool diskPersistent = true;
        uint diskExpiryThreadIntervalSeconds = 120;
        uint maxEntriesLocalDisk = 10000;
    }

    struct CookieConf {
        string domain = "";
        string path = "/";
        int expires = 3600;
        bool secure = false;
        bool httpOnly = true;
    }

    struct SessionConf {
        string storage = "memory";
        string prefix = "huntsession_";
        string args = "/tmp";
        uint expire = 3600; // in seconds
    }

    struct HttpConf {
        string address = "0.0.0.0";
        string path = DEFAULT_STATIC_FILES_LACATION;
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

    struct HttpsConf {
        bool enabled = false;
        string protocol;
        string keyStore;
        string keyStoreType;
        string keyStorePassword;
    }

    struct RouteConf {
        string groups;
    }

    struct LoggingConfig {
        string level = "all";
        string path;
        string file = "";
        bool disableConsole = false;
        string maxSize = "8M";
        uint maxNum = 8;
    }

    struct MemcacheConf {
        bool enabled = false;
        string servers;
    }
    
    struct AmqpConf {
        bool enabled = false;
        string host = "127.0.0.1";
        string username = "guest";
        string password = "guest";
        ushort port = 5672;
        uint timeout = 15000;
    }

    struct RedisConf {
        bool enabled = false;
        string host = "127.0.0.1";
        string password = "";
        ushort database = 0;
        ushort port = 6379;
        uint timeout = 5000;
        RedisPoolConf pool;
        RedisClusterConf cluster;
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

    struct RedisClusterConf {
        bool enabled = false;
        string[] nodes;
    }

    struct QueueConf {
        // Drivers: "memeory", "amqp", "redis", "null"
        string driver = null;
    }

    struct UploadConf {
        string path = "/tmp";
        long maxSize = 4 * 1024 * 1024;
    }

    struct MailSmtpConf {
        string host;
        string channel;
        ushort port;
        string protocol;
        string user;
        string password;
    }

    struct MailConf {
        MailSmtpConf smtp;
    }

    struct DbPoolConf {
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

    struct DatabaseConf {
        
        string url() {
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

        DbPoolConf pool;
    }

    struct DateConf {
        string format;
        string timeZone;
    }

    struct CornConf {
        string noon;
    }

    struct ServiceConf {
        string address = "127.0.0.1";
        ushort port = 8080;
        int workerThreads = 1;
        string password;
    }

    struct RpcConf {
        bool enabled = true;
        ServiceConf service;
    }

    struct View {
        string path = "./resources/views/";
        string ext = ".html";
        uint arrayDepth = 3;
    }

    struct TraceConf {
        bool enable = false;
        bool b3Required = true;
        TraceService service;
        string zipkin = "http://127.0.0.1:9411/api/v2/spans";
    }

    struct TraceService {
        string host;
        ushort port;
    }

    DatabaseConf database;
    ApplicationConf application;
    AuthConf auth;
    StaticFilesConf staticfiles;
    CookieConf cookie;
    SessionConf session;
    CacheConf cache;
    HttpConf http;
    HttpsConf https;
    RouteConf route;
    MemcacheConf memcache;
    AmqpConf amqp;
    QueueConf queue;
    RedisConf redis;
    LoggingConfig logging;
    UploadConf upload;
    CornConf cron;
    DateConf date;
    MailConf mail;
    RpcConf rpc;
    View view;
    TraceConf trace;

    MultipartOptions multipartConfig() {
        if (_multipartConfig is null) {
            string path = buildPath(DEFAULT_TEMP_PATH, upload.path);
            if (!path.exists()) {
                // for Exception now?
                path.mkdirRecurse();
            }
            _multipartConfig = new MultipartOptions(path, upload.maxSize, upload.maxSize, 50);
        }
        return _multipartConfig;
    }

    private MultipartOptions _multipartConfig;

    this() {
        http.workerThreads = totalCPUs * 4;
        http.ioThreads = totalCPUs;
        upload.path = DEFAULT_TEMP_PATH;
        view.path = DEFAULT_TEMPLATE_PATH;
        application.langLocation = DEFAULT_LANGUAGE_PATH;
    }
}

import core.sync.rwmutex;

import std.array;
import std.file;
import std.path;
import std.exception : basicExceptionCtors;

/** 
 * 
 */
class ConfigNotFoundException : Exception {
    mixin basicExceptionCtors;
}

// ConfigManager configManager() {
//     return _manger;
// }

// shared static this() {
//     _manger = new ConfigManager();
// }

// private:
// __gshared ConfigManager _manger;
