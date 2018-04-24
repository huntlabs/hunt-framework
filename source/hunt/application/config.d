/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.application.config;

import std.exception;
import std.parallelism : totalCPUs;
import std.socket : Address, parseAddress;
import kiss.log;
import std.string;

import hunt.init;
import hunt.text.configuration;
import hunt.application.application : WebSocketFactory;
import hunt.application.application;

import collie.codec.http.server.httpserveroptions;

final class AppConfig
{
    alias AddressList = Address[];

    struct ApplicationConf
    {
        string name = "HUNT APPLICATION";
        string baseUrl;
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
        uint expire = 3600;
    }

    struct CacheConf
    {
		string storage = "memory";
		string args = "/tmp";
		bool   enableL2 = false;	
    }

    struct HttpConf
    {
        string address = "0.0.0.0";
        ushort port = 8080;
        uint workerThreads = 4;
        uint ioThreads = 2;
        size_t keepAliveTimeOut = 30;
        size_t maxHeaderSize = 60 * 1024;
        int cacheControl;
        string path;
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

    struct LogConfig
    {
        string level = "all";
        string path;
        string file = "";
		bool   disableConsole = false;
		string maxSize = "8M";
		uint   maxNum = 8;
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
        uint maxConnection = 10;
        uint minConnection = 10;
        uint timeout = 10000;
    }

    struct DBConfig
    {
        string url;
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

    struct ServiceConf {
        string address = "127.0.0.1";
        ushort port;
        int workerThreads;
        string password;
    }

    struct RpcConf {
        bool enabled = true;
        ServiceConf service;
    }

    DBConfig database;
    ApplicationConf application;
    SessionConf session;
    CacheConf cache;
    HttpConf http;
    HttpsConf https;
    RouteConf route;
    MemcacheConf memcache;
    RedisConf redis;
    LogConfig log;
    UploadConf upload;
    CornConf cron;
    DateConf date;
    MailConf mail;
    RpcConf rpc;

    @property Configuration config(){return _config;}

    static AppConfig parseAppConfig(Configuration conf)
    {
        AppConfig app = new AppConfig();

        app._config = conf;
        
        collectException(conf.application.name.value,    app.application.name);
        collectException(conf.application.baseUrl.value,    app.application.baseUrl);
        collectException(conf.application.defaultCookieDomain.value,    app.application.defaultCookieDomain);
        collectException(conf.application.defaultLanguage.value,    app.application.defaultLanguage);
        collectException(conf.application.languages.value,    app.application.languages);
        collectException(conf.application.secret.value,    app.application.secret);
        collectException(conf.application.encoding.value,    app.application.encoding);
        collectException(conf.application.staticFileCacheMinutes.as!int,    app.application.staticFileCacheMinutes);

		collectException(conf.session.storage.value(),    app.session.storage);
        collectException(conf.session.prefix.value(),    app.session.prefix);
		collectException(conf.session.args.value(),    app.session.args);
        collectException(conf.session.expire.as!uint(),     app.session.expire);

		collectException(conf.cache.storage.value(),    app.cache.storage);
        ///collectException(conf.cache.prefix.value(),    app.cache.prefix);
		collectException(conf.cache.args.value(),     app.cache.args);

        collectException(conf.http.address.value(), app.http.address);
        collectException(conf.http.port.as!ushort(), app.http.port);
        collectException(conf.http.workerThreads.as!uint(), app.http.workerThreads);
        collectException(conf.http.ioThreads.as!uint(), app.http.ioThreads);
        collectException(conf.http.maxHeaderSize.as!size_t(), app.http.maxHeaderSize);
        collectException(conf.http.keepAliveTimeOut.as!size_t(), app.http.keepAliveTimeOut);
        collectException(conf.http.cacheControl.as!int(), app.http.cacheControl);
        collectException(conf.http.path.value(), app.http.path);

        collectException(conf.https.enabled.as!bool(), app.https.enabled);
        collectException(conf.https.protocol.value(), app.https.protocol);
        collectException(conf.https.keyStore.value(), app.https.keyStore);
        collectException(conf.https.keyStoreType.value(), app.https.keyStoreType);

        collectException(conf.route.groups.value(), app.route.groups);

        collectException(conf.memcache.enabled.as!bool(), app.memcache.enabled);
        collectException(conf.memcache.servers.value(), app.memcache.servers);

        collectException(conf.redis.enabled.as!bool(), app.redis.enabled);
        collectException(conf.redis.host.value(), app.redis.host);
        collectException(conf.redis.password.value(), app.redis.password);
        collectException(conf.redis.database.as!ushort(), app.redis.database);
        collectException(conf.redis.port.as!ushort(), app.redis.port);
        collectException(conf.redis.timeout.as!uint(), app.redis.timeout);

        collectException(conf.log.level.value(), app.log.level);
        collectException(conf.log.path.value(), app.log.path);
        collectException(conf.log.file.value(), app.log.file);
		collectException(conf.log.disableConsole.as!bool(), app.log.disableConsole);
		collectException(conf.log.maxSize.value(), app.log.maxSize);
		collectException(conf.log.maxNum.as!uint(), app.log.maxNum);

        collectException(conf.upload.path.value(), app.upload.path);
        collectException(conf.upload.maxSize.as!uint(), app.upload.maxSize);

        collectException(conf.cron.noon.value(), app.cron.noon);

        collectException(conf.date.format.value(), app.date.format);
        collectException(conf.date.timeZone.value(), app.date.timeZone);

        collectException(conf.database.url.value(), app.database.url);
        collectException(conf.database.pool.maxConnection.as!uint(), app.database.pool.maxConnection);
        collectException(conf.database.pool.minConnection.as!uint(), app.database.pool.minConnection);
        collectException(conf.database.pool.timeout.as!uint(), app.database.pool.timeout);

        collectException(conf.mail.smtp.host.value(), app.mail.smtp.host);
        collectException(conf.mail.smtp.channel.value(), app.mail.smtp.channel);
        collectException(conf.mail.smtp.port.as!ushort(), app.mail.smtp.port);
        collectException(conf.mail.smtp.protocol.value(), app.mail.smtp.protocol);.
        collectException(conf.mail.smtp.user.value(), app.mail.smtp.user);
        collectException(conf.mail.smtp.password.value(), app.mail.smtp.password);

        collectException(conf.rpc.enabled.as!bool(), app.rpc.enabled);
        collectException(conf.rpc.service.address.value(), app.rpc.service.address);
        collectException(conf.rpc.service.port.as!ushort(), app.rpc.service.port);
        collectException(conf.rpc.service.workerThreads.as!int(), app.rpc.service.workerThreads);.
        collectException(conf.rpc.service.password.value(), app.rpc.service.password);

        return app;
    }

private:
    Configuration _config;

    this()
    {
        http.workerThreads = totalCPUs;
    }
}

import core.sync.rwmutex;

import std.file;
import std.path;

class ConfigNotFoundException : Exception
{
    mixin basicExceptionCtors;
}

class ConfigManager
{
    @property AppConfig app()
    {
        if(!_app)
        {
            setAppSection("");
        }

        return _app;
    }

    @property string path()
    {
        return this._path;
    }

    void setConfigPath(string path)
    {
        if(path.empty)
            return;

        if(path[$-1] == '/')
            this._path = path;
        else
            this._path = path ~ "/";
    }

    void setAppSection(string sec, string fileName = "application.conf")
    {
        auto con = new Configuration(path ~ fileName, sec);
        _app = AppConfig.parseAppConfig(con);
    }

    Configuration config(string key)
    {
        import std.format;
        Configuration v = null;
        synchronized(_mutex.reader)
        {
            v =  _conf.get(key, null);
        }

        enforce!ConfigNotFoundException(v, format(" %s is not in config! ", key));

        return v;
    }

    void addConfig(string key, Configuration conf)
    {
        _mutex.writer.lock();
        scope(exit)_mutex.writer.unlock();
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
    
    ~this(){_mutex.destroy;}

    AppConfig _app;
    
    Configuration[string] _conf;

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
