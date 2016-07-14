module hunt.application.config.db;

import hunt.text.conf;
import std.file;
import std.experimental.logger;

class DBConf
{
	this(string file)
	{
		if(!exists(file)) return;
		_ini = new Conf(file);
		string type = _ini.get("db.type");
		string host = _ini.get("db.host");
		if(type.length > 0 && host.length > 0)
		{
			_url ~= type ~ "://" ~ host;
			string port = _ini.get("db.port");
			if(port.length > 0)
				_url ~= ":" ~ port;
			port  = _ini.get("db.dbname");
			if(port.length > 0)
				_url ~= "/" ~ port;
			port  = _ini.get("db.username");
			if(port.length > 0)
				_url ~= "?username=" ~ port;
			port  = _ini.get("db.password");
			if(port.length > 0)
				_url ~= "&password=" ~ port;
			trace(_url);
		}
	}


	bool isVaild()
	{
		return _url.length > 5;
	}

	string getUrl()
	{
		return _url;
	}


private:
	string _url;
	Conf _ini;
}