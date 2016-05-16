import std.stdio;
import std.functional;

import hunt.http.cookie;

import hunt.webapplication;

void hello(Request, Response res)
{
    res.setContext("hello world");
    res.setHeader("content-type","text/html;charset=UTF-8");
    res.done();
}

void main()
{
	testIni();
	WebApplication app = new WebApplication();
	app.addRouter("GET","/test",toDelegate(&hello));
	app.addRouter("GET","/",toDelegate(&hello));
	app.bind(8080);
	app.run();
}



void testIni()
{
	import hunt.config;
	import std.path;
	import std.experimental.logger;
	auto ini = new Ini(buildPath(huntConfigPath , "./config/http.conf"));
	log(ini.value("server", "port") );
}
