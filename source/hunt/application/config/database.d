module hunt.application.config.database;

import hunt.text.conf;
import std.file;
import std.experimental.logger;

class DBConf
{
	this(string file)
	{
		if(!exists(file)) return;
		_ini = new Conf(file);
		string type = _ini.get("database.driver");
		string host = _ini.get("database.host");
		if(type.length > 0 && host.length > 0)
		{
			_url ~= type ~ "://" ~ host;
			string port = _ini.get("database.port");
			if(port.length > 0)
				_url ~= ":" ~ port;
			port  = _ini.get("database.dbname");
			if(port.length > 0)
				_url ~= "/" ~ port;
			port  = _ini.get("database.username");
			if(port.length > 0)
				_url ~= "?username=" ~ port;
			port  = _ini.get("database.password");
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

	string getValue(string str)
	{
		string key = "database." ~ str;
		if(_ini)
			return _ini.get(key);

		return string.init;
	}

private:
	string _url;
	Conf _ini;
}