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

module hunt.application.config;

import std.exception;
import std.parallelism : totalCPUs;
import std.socket : Address, parseAddress;
import std.format;
import std.string;

import kiss.util.configuration;
import kiss.logger;
import hunt.init;
import hunt.application.application : WebSocketFactory;
import hunt.application.application;

import collie.codec.http.server.httpserveroptions;

@Configuration("hunt")
final class AppConfig
{
    struct ApplicationConf
    {
        string name = "Hunt Application";
        string baseUrl = "http://localhost:8080/";
        string defaultCookieDomain = ".example.com";
        string defaultLanguage = "zh-CN";
        string languages = "zh-CN,en-US";
        string secret = "CD6CABB1123C86EDAD9";
        string encoding = "utf-8";
        int staticFileCacheMinutes = 30;
    }

    struct SessionConf
    {
        string storage = "memory";
        string prefix = "huntsession_";
        string args = "/tmp";
        uint expire = 3600; // in seconds
    }

    struct CacheConf
    {
        string storage = "memory";
        string args = "/tmp";
        bool enableL2 = false;
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
    }

    struct UploadConf
    {
        string path;
        uint maxSize = 4 * 1024 * 1024;
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
        int port = 5432;
        string database = "test";
        string username = "root";
        string password = "";
        string charset = "utf8";
        string prefix = "";
        bool enabled = true;
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
        string path = "./views/";
        string ext = ".dhtml";
    }

    DatabaseConf database;
    ApplicationConf application;
    SessionConf session;
    CacheConf cache;
    HttpConf http;
    HttpsConf https;
    RouteConf route;
    MemcacheConf memcache;
    RedisConf redis;
    LoggingConfig logging;
    UploadConf upload;
    UploadConf download () { return upload;}
    CornConf cron;
    DateConf date;
    MailConf mail;
    RpcConf rpc;
    View view;

    this()
    {
        http.workerThreads = totalCPUs;
        download.path = DEFAULT_ATTACHMENT_PATH;
    }
}

import core.sync.rwmutex;

import std.file;
import std.path;

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
    @property AppConfig app(string section="", string fileName = "application.conf")
    {
        if (!_app)
        {
            setAppSection(section, fileName);
        }

        return _app;
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
            logDebugf("using the config file: %s", fullName);
            ConfigBuilder con = new ConfigBuilder(fullName, sec);
            _app = con.build!(AppConfig, "hunt")();
            addConfig("hunt", con);
        }
        else
        {
            logDebug("using default settings.");
            _app = new AppConfig();
        }
    }

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

    AppConfig _app;
    ConfigBuilder[string] _conf;
    string _path;
    ReadWriteMutex _mutex;
}

@property ConfigManager Config()
{
    return _manger;
}

shared static this()
{
    _manger = new ConfigManager();
}

private:
__gshared ConfigManager _manger;
