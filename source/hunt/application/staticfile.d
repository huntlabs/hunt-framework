module hunt.application.staticfile;

import std.conv;
import std.string;
import std.datetime;

import hunt;
import hunt.application.controller;

class StaticfileController : Controller
{
    mixin MakeController;
    
    @Action
    void doStaticFile()
    {
    	if (request.route.staticFilePath == string.init)
    	{
    		response.do404();
    		
    		return;
    	}
    	
    	ubyte[] content = StaticfileCache.instance.getCache(request.path);

    	if (content != null)
    	{
    		response.setContext(content);
    		
    		return;
    	}

    	string staticFilename = "";
     	string path = request.route.staticFilePath;
        	
    	if (!path.startsWith("./"))
    	{
    		if (path.startsWith("/"))
    		{
    			path = "." ~ path;
    		}
    		else
    		{
    			path = "./" ~ path;
    		}
    	}
    	
    	if (!path.endsWith("/"))
    	{
    		path ~= "/";
    	}

    	staticFilename = path ~ chompPrefix(request.path, request.route.getPattern());
		trace(staticFilename);
		
		if ((staticFilename == string.init) || (!std.file.exists(staticFilename)))
        {
			response.do404();
			
			return;
		}

    	content = cast(ubyte[])read(staticFilename);
	    StaticfileCache.instance.setCache(request.path, content);
		response.setContext(content);
    }
}

class StaticfileCache
{
	__gshared static StaticfileCache instance;

	static this()
	{
		if (instance is null)
		{
			instance = new StaticfileCache();
		}
	}

	private class FileContent
	{
		ubyte[] content;
		SysTime cacheTime;
		
		this(ubyte[] content)
		{
			this.content = content;
			this.cacheTime = Clock.currTime();
		}
	}

	private FileContent[string] _contents;
	
	ubyte[] getCache(string key)
	{
		FileContent fc = _contents.get(key, null);

		if ((fc is null) || ((Clock.currTime() - fc.cacheTime).total!"minutes" > Config.app.application.staticFileCacheMinutes))
		{
			return null;
		}

		return fc.content;
	}
	
	void setCache(string key, ubyte[] content)
	{
		_contents[key] = new FileContent(content);
	}
}