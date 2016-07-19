module hunt.i18n;

import std.path;
import std.file;
import std.algorithm;
import std.array;
import std.experimental.logger;
import std.stdio;
import std.string;

alias StrStr = string[string];
alias StrStrStr = string[string][string];

enum I18N_DEFAULT_LOCAL = "zh-cn";

///国际化
class I18n
{
	private{
		StrStrStr _res;
		__gshared I18n _instance;
	}
	
	this()
	{
		// Constructor code
	}
	
	static auto instance()
	{
		if(_instance is null)
		{
			_instance = new I18n();
		}
		return _instance;
	}
	
	
	///加载资源文件
	bool loadLangResources(string path, lazy string ext = "res")
	{
		auto resfiles = std.file.dirEntries(path, "*.{res}", SpanMode.depth)
			.filter!(a => a.isFile)
				.map!(a => std.path.absolutePath(a.name))
				.array;
		if(resfiles.length == 0)
		{
			log("lang res file is empty");
			return false;
		}
		
		foreach(r; resfiles)
		{
			parseResFile(r);
		}
		return true;
	}
	
	@property StrStrStr resources()
	{
		return this._res;
	}
	
	///解析文件
	private bool parseResFile(string fileName)
	{
		auto f = File(fileName,"r");
		scope(exit)
		{
			f.close();
		}
		
		if(!f.isOpen()) return false;
		
		string _res_file_name = baseName(fileName, extension(fileName));
		string _loc = baseName(dirName(fileName));
		
		int line = 1;
		while(!f.eof())
		{
			scope(exit) 
				line += 1;
			string str = f.readln();
			str = strip(str);
			if(str.length == 0) 
				continue;
			if(str[0] == '#' || str[0] == ';') 
				continue;
			auto len = str.length -1;
			
			auto site = str.indexOf("=");
			if(site == -1)
			{
				import std.format;
				throw new Exception(format("the format is erro in file %s, in line %d : string: %s",fileName,line, str));
			}
			string key = str[0..site].strip;
			if(key.length == 0)
			{
				import std.format;
				throw new Exception(format("the Key is empty in file %s, in line %d",fileName,line));
			}
			string value  = str[site + 1..$].strip;
			
			this._res[_loc][_res_file_name ~ "." ~ key] = value;
		}
		return true;
	}
	
}

///设置本地化
private string _local;

private @property string getLocal(){
	if(_local)
		return _local;
	return I18N_DEFAULT_LOCAL;
}

///设置本地化
@property setLocal(string _l)
{ 
	_local = toLower(_l);
}

///key is [filename.key]
string getText(string key, lazy string default_value = string.init)
{ 
	auto p = getLocal in I18n.instance.resources;
	if(p !is null)
	{
		return p.get(key, default_value);
	}
	log("not support local ", getLocal, " change for ", I18N_DEFAULT_LOCAL);
	
	p = I18N_DEFAULT_LOCAL in I18n.instance.resources;
	
	if(p !is null)
	{
		return p.get(key, default_value);
	}
	
	log("not support local ", I18N_DEFAULT_LOCAL );
	
	return default_value;
}



unittest{
	
	I18n i18n = I18n.instance();
	i18n.loadLangResources("./resources/lang");
	writeln(i18n.resources);
	
	
	///
	setLocal("en-br");
	assert( getText("message.hello-world", "empty") == "你好，世界");
	
	///
	setLocal("zh-cn");
	assert( getText("email.subject", "empty") == "收件人");
	
	
	setLocal("en-us");
	assert( getText("email.subject", "empty") == "empty");
}