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
    	
    	ubyte[] content = Application.getInstance.cache().get!(ubyte[])(request.path);

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
	    Application.getInstance.cache().set(request.path, content, Config.app.application.staticFileCacheMinutes);
		response.setContext(content);
    }
}