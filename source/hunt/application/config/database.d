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
		string type = _ini.get("default.driver");
		string host = _ini.get("default.host");
		if(type.length > 0 && host.length > 0)
		{
			_url ~= type ~ "://" ~ host;
			string port = _ini.get("default.port");
			if(port.length > 0)
				_url ~= ":" ~ port;
			port  = _ini.get("default.dbname");
			if(port.length > 0)
				_url ~= "/" ~ port;
			port  = _ini.get("default.username");
			if(port.length > 0)
				_url ~= "?username=" ~ port;
			port  = _ini.get("default.password");
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
		if(_ini)
			return _ini.get(str);

		return string.init;
	}

	Conf getConfig(){return _ini;}
	
private:
	string _url;
	Conf _ini;
}