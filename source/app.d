import std.stdio;
import hunt.http.cookie;

void main()
{
	testIni();
}

void testIni()
{
	import hunt.config;
	import std.path;
	import std.experimental.logger;
	auto ini = new Ini(buildPath(huntConfigPath , "./config/http.conf"));
	log(ini.value("server", "port") );
}
