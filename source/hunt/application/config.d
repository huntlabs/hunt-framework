module hunt.application.config;

import std.exception;
import std.parallelism : totalCPUs;
import std.socket : Address, parseAddress;
import std.experimental.logger;

import hunt.text.configuration;
import hunt.application.application : WebSocketFactory;

import hunt.routing.configbase;

final class AppConfig
{
	struct CookieConfig
	{
		string domain = ".huntframework.com";
		string prefix = "hunt_";
		uint expire = 3600;
	}

	struct HttpConfig
	{
		uint keepAliveTimeOut = 30;
		uint maxBodySzie = 8 * 1024 * 1024;
		uint maxHeaderSize = 4 * 1024;
		uint headerSection = 4 * 1024;
		uint requestSection = 8 * 1024;
		uint responseSection = 8 * 1024;
		WebSocketFactory webSocketFactory = null;

		CookieConfig cookie;
	}

	struct ServerConfig
	{
		uint workThreads;// = totalCPUs;
		string listen = "0.0.0.0";
		ushort port = 8081;
		string defaultLanguage = "zh-cn";
		string encoding  = "utf-8";
		string timeZone = "Asia/Shanghai";

		Address bindAddress(){
			trace("------------- ;isten : ", listen);
			Address addr = parseAddress(listen,port);
			return addr;
		}
	}

	struct LogConfig
	{
		string level = "warning";
		string file = "";
	}

	struct DBConfig
	{
		string type;
		string host;
		string port;
		string dbname;
		string username;
		string password;
	}

	DBConfig db;
	HttpConfig http;
	ServerConfig server;
	LogConfig log;

	@property Configuration config(){return _config;}

	static AppConfig parseAppConfig(Configuration conf)
	{
		AppConfig app = new AppConfig();
		app._config = conf;
		collectException(conf.http.addr.value(),app.server.listen);
		collectException(conf.http.port.as!ushort(),app.server.port);
		collectException(conf.http.worker_threads.as!uint(),app.server.workThreads);
		collectException(conf.config.default_language.value(),app.server.defaultLanguage);
		collectException(conf.config.encoding.value(), app.server.encoding);
		collectException(conf.config.time_zone.value(), app.server.timeZone);
		collectException(conf.http.keepalive_timeout.as!uint(), app.http.keepAliveTimeOut);
		collectException(conf.http.max_body_szie.as!uint(), app.http.maxBodySzie);
		collectException(conf.http.max_header_size.as!uint(), app.http.maxHeaderSize);
		collectException(conf.http.header_section.as!uint(), app.http.headerSection);
		collectException(conf.http.request_section.as!uint(), app.http.requestSection);
		collectException(conf.http.response_section.as!uint(), app.http.responseSection);
		string ws;
		collectException(conf.http.webSocket_factory.value(), ws);
		if(ws.length > 0){
			auto obj = Object.factory(ws);
			if(obj) app.http.webSocketFactory = cast(WebSocketFactory)obj;
		}
		collectException(conf.log.level.value(), app.log.level);
		collectException(conf.log.file.value(), app.log.file);

		collectException(conf.db.type.value(), app.db.type);
		collectException(conf.db.host.value(), app.db.host);
		collectException(conf.db.port.value(), app.db.port);
		collectException(conf.db.dbname.value(), app.db.dbname);
		collectException(conf.db.username.value(), app.db.username);
		collectException(conf.db.password.value(), app.db.password);
		return app;
	}

private:
	Configuration _config;

	this(){server.workThreads = totalCPUs;}
}

import core.sync.rwmutex;
import std.file;
import std.path;

import hunt.router.config;

class ConfigNotFoundException : Exception
{
	mixin basicExceptionCtors;
}

class ConfigManger
{
	@property app() {
		if(!_app) {
			setAppSection("");
		}
		return _app;
	}
	@property router(){
		if(!_router)
		{
			string ph = path ~ "/routes";
			trace("router path is : ", ph);
			if (exists(ph)) {
				_router = new RouterConfig(ph);
			}
		}
		return _router;
	}

	void setConfigPath(string path)
	{
		import std.string;
		if(path.length < 0) return;
		if(path[$ -1] != '/') path ~= "/";
	}

	void setAppSection(string sec)
	{
		auto con = new Configuration(path ~ "/application.conf",sec);
		_app = AppConfig.parseAppConfig(con);
	}
	
	Configuration config(string key)
	{
		import std.format;
		Configuration v = null;
		synchronized(_mutex.reader) {
			v =  _conf.get(key, null);
		}
		enforce!ConfigNotFoundException(v,format(" %s is not in config! ",key));
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
	this(){
		_mutex = new ReadWriteMutex();
		path = dirName(thisExePath) ~ "/config/";
	}
	~this(){_mutex.destroy;}
	AppConfig _app;
	RouterConfigBase _router;
	
	Configuration[string] _conf;

	string path;

	ReadWriteMutex _mutex;
}

@property Config(){return _manger;}

shared static this()
{
	_manger = new ConfigManger();
}

private:
__gshared ConfigManger _manger;