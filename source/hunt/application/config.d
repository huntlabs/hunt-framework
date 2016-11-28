module hunt.application.config;

import std.exception;
import std.parallelism : totalCPUs;
import std.socket : Address, parseAddress;
import std.experimental.logger;
import std.string;

import hunt.text.configuration;
import hunt.application.application : WebSocketFactory;

import hunt.router.configbase;
import collie.codec.http.server.httpserveroptions;

final class AppConfig
{
	alias AddressList = Address[];
	struct CookieConfig
	{
		string domain = ".huntframework.com";
		string prefix = "hunt_";
		uint expire = 3600;
	}

	struct ServerConfig
	{
		uint workerThreads; // default is totalCPUs;
		uint ioThreads = 2;
		string defaultLanguage = "zh-cn";
		string encoding  = "utf-8";
		string timeZone = "Asia/Shanghai";
		uint keepAliveTimeOut = 30;
		uint listenBacklog = 1024;
		uint maxHeaderSize = 60;
		uint maxBodySzie = 8 * 1024;
		uint fastOpenQueueSize = 10000;
		WebSocketFactory webSocketFactory = null;
		
		CookieConfig cookie;


		AddressList bindAddress(){
			return _binds;
		}

	private:
		AddressList _binds;
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
	ServerConfig server;
	LogConfig log;

	@property Configuration config(){return _config;}

	static AppConfig parseAppConfig(Configuration conf)
	{
		AppConfig app = new AppConfig();

		app._config = conf;
		string[] ips;
		collectException(conf.server.binds.values(),ips);
		collectException(conf.server.worker_threads.as!uint(),app.server.workerThreads);
		collectException(conf.server.io_threads.as!uint(),app.server.ioThreads);
		collectException(conf.server.fast_open.as!uint(),app.server.fastOpenQueueSize);
		collectException(conf.server.default_language.value(),app.server.defaultLanguage);
		collectException(conf.server.encoding.value(), app.server.encoding);
		collectException(conf.server.time_zone.value(), app.server.timeZone);
		collectException(conf.server.timeout.as!uint(), app.server.keepAliveTimeOut);
		collectException(conf.server.max_body_szie.as!uint(), app.server.maxBodySzie);
		collectException(conf.server.max_header_size.as!uint(), app.server.maxHeaderSize);
		collectException(conf.server.cookie.domain.value(), app.server.cookie.domain);
		collectException(conf.server.cookie.prefix.value(), app.server.cookie.prefix);
		collectException(conf.server.cookie.expire.as!uint(), app.server.cookie.expire);
		app.server.maxBodySzie = app.server.maxBodySzie << 10;// * 1024
		app.server.maxHeaderSize = app.server.maxHeaderSize << 10;// * 1024
		if(ips.length == 0){ 
			ips ~= "127.0.0.1:8080";
			ips ~= "::1:8080";
		}
		foreach(ip;ips){
			import std.conv;
			auto index = lastIndexOf(ip,':');
			if(index <= 0 ) continue;
			string tip =  strip(ip[0..index]);
			string tport = strip(ip[index+1..$]);
			ushort port = 0;
			collectException(to!(ushort)(tport),port);
			if(port == 0)continue;
			Address addr;
			collectException(parseAddress(tip,port),addr);
			if(addr is null) continue;
			app.server._binds ~= addr;
		}
		string ws;
		collectException(conf.server.webSocket_factory.value(), ws);
		
		if(ws.length > 0){
			auto obj = Object.factory(ws);
			if(obj) app.server.webSocketFactory = cast(WebSocketFactory)obj;
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

	this(){server.workerThreads = totalCPUs;}
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
	this()
	{
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
