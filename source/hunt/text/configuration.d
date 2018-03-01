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

module hunt.text.configuration;

import std.traits;
import std.conv;
import std.exception;
import std.array;
import std.stdio;
import std.string;
import std.experimental.logger;

class ConfFormatException : Exception
{
	mixin basicExceptionCtors;
}

class NoValueHasException : Exception
{
	mixin basicExceptionCtors;
}

class Configuration
{
	class ConfigurationValue
	{
		@property value(string name){
			auto v =  _map.get(name, null);
			enforce!NoValueHasException(v,format(" %s is not in config! ",name));
			return v;
		}

		@property value(){
			return _value;
		}
		
		auto opCast(T)(){
                    static if(is(T == bool))
                        return as!bool(true);
                    else static if(isSomeString!T)
                        return cast(T)(value());
                    else static if(isNumeric!(T))
                        return as!T(T.init);
                    else
                        static assert(0,"not support type");
		}

		auto as(T)(T value = T.init) if(isNumeric!(T))
		{
			if(_value.length == 0)
				return value;
			else
				return to!T(_value);
		}
		
		auto as(T : bool)(T value = T.init)
		{
			if(_value.length == 0 || _value == "false" || _value == "0")
				return false;
			else
				return true;
		}

		auto as(T : string)(T value = T.init)
		{
			if(_value.length == 0)
				return value;
			else
				return _value;
		}

		auto opDispatch(string s)()
		{
			return value(s);
		}
		
	private :
		string _value;
		ConfigurationValue[string] _map;
	}
	
	this(string filename, string section = "")
	{
		_section = section;
		loadConfig(filename);
	}
	
	@property value(string name){
		return _value.value(name);
	}
	
	auto opDispatch(string s)()
	{
		return _value.opDispatch!(s)();
	}
	
private:
	void loadConfig(string filename)
	{
		_value = new ConfigurationValue();

		import std.file;
		if(!exists(filename))
		{	
			throw new Exception("The config file doesn't exist: " ~ filename);
		}
		import std.format;
		auto f = File(filename,"r");
		if(!f.isOpen()) return;
		scope(exit) f.close();
		string section = "";
		int line = 1;
		while(!f.eof())
		{
			scope(exit) line += 1;
			string str = f.readln();
			str = strip(str);
			if(str.length == 0) continue;
			if(str[0] == '#' || str[0] == ';') continue;
			auto len = str.length -1;
			if(str[0] == '[' && str[len] == ']')
			{
				section = str[1..len].strip;
				continue;
			}
			if(section != _section && section != "")
				continue;// 不是自己要读取的分段，就跳过
			auto site = str.indexOf("=");
			enforce!ConfFormatException((site > 0),format("the format is erro in file %s, in line %d",filename,line));
			string key = str[0..site].strip;
			setValue(split(key,'.'),str[site + 1..$].strip);
		}
	}
	
	void setValue(string[] list, string value)
	{
		auto cvalue = _value;
		foreach(ref str ; list){
			if(str.length == 0) continue;
			auto tvalue = cvalue._map.get(str,null);
			if(tvalue is null){ // 不存在就追加一个
				tvalue = new ConfigurationValue();
				cvalue._map[str] = tvalue;
			}
			cvalue = tvalue;
		}
		if(cvalue is _value)
			return;
		cvalue._value = value;
	}
	
private:
	string _section;
	ConfigurationValue _value;
}


unittest
{
	import std.stdio;
	import FE = std.file;
	FE.write("test.config","http.listen = 100 \napp.test =  \n# this is  \n ; start dev\n [dev]\napp.test = dev");
	auto conf = new Configuration("test.config");
	assert(conf.http.listen.as!long() == 100);
	assert(conf.app.test.value() == "");
	
	auto confdev = new Configuration("test.config","dev");
	long tv = cast(long)confdev.http.listen;
	assert(tv == 100);
	assert(confdev.http.listen.as!long() == 100);
	writeln("----------" ,confdev.app.test.value());
	string tvstr = cast(string)confdev.app.test;
	auto tvstrw = cast(wstring)confdev.app.test;
	assert(tvstr == "dev");
	assert(confdev.app.test.value() == "dev");
	bool tvBool = cast(bool)confdev.app.test;
	assert(tvBool);

	string str;
	auto e = collectException!NoValueHasException(confdev.app.host.value(), str);
	assert(e && e.msg == " host is not in config! ");
}
