module hunt.application.staticfile;

import std.conv;
import std.string;
import std.datetime;
import std.path;
import std.digest.md;
import core.time;
static import std.stdio;

import kiss.logger;
import hunt;
import hunt.application.controller;
import hunt.application.config;
import hunt.utils.string;

/**
*/
class StaticfileController : Controller
{
    mixin MakeController;
    
    @Action
    Response doStaticFile()
    {
		string currentPath = request.route.staticFilePath;
		logDebug("currentPath: ", currentPath);
        if (currentPath == string.init)
        {
			// FIXME: Needing refactor or cleanup -@zxp at 5/25/2018, 10:02:46 AM
			// get the value from the configuration
			currentPath = "wwwroot";
        }

        string staticFilename = mendPath(currentPath);
		logDebug ("staticFilename: ", staticFilename);

        if (staticFilename == string.init)
        {
            response.do404();
            return response;
        }

		currentPath = staticFilename;
		string[] defaultIndexFiles = ["index.html", "index.htm", "default.html", "default.htm", "home.html"];
		bool isFileExisted = exists(currentPath);
		if(isFileExisted && isDir(currentPath))
		{
			if(currentPath[$-1] != '/')
				currentPath ~= "/";
			foreach(string f; defaultIndexFiles)
			{
				staticFilename = currentPath ~ f;
				if(exists(staticFilename))
				{
					isFileExisted = true;
					break;
				}
			}
		}

        if (!isFileExisted)
        {
			logWarning("No default index files (like index.html) found in: ", currentPath);
            response.do404();
            return response;
        }

        FileInfo fi = makeFileInfo(staticFilename);
        auto lastModified = toRFC822DateTimeString(fi.timeModified.toUTC());
        auto etag = "\"" ~ hexDigest!MD5(staticFilename ~ ":" ~ lastModified ~ ":" ~ to!string(fi.size)).idup ~ "\"";
    
        response.setHeader(HTTPHeaderCode.LAST_MODIFIED, lastModified);
        response.setHeader(HTTPHeaderCode.ETAG, etag);

        if (Config.app.application.staticFileCacheMinutes > 0)
		{
            auto expireTime = Clock.currTime(UTC()) + dur!"minutes"(Config.app.application.staticFileCacheMinutes);
            response.setHeader(HTTPHeaderCode.EXPIRES, toRFC822DateTimeString(expireTime));
            response.setHeader(HTTPHeaderCode.CACHE_CONTROL, "max-age=" ~ to!string(Config.app.application.staticFileCacheMinutes * 60));
        }

        if ((request.headerExists(HTTPHeaderCode.IF_MODIFIED_SINCE) && (request.header(HTTPHeaderCode.IF_MODIFIED_SINCE) == lastModified)) ||
            (request.headerExists(HTTPHeaderCode.IF_NONE_MATCH) && (request.header(HTTPHeaderCode.IF_NONE_MATCH) == etag)))
        {
                response.setStatus(HttpStatusCodes.NOT_MODIFIED);

                return response;
		}
	
		auto mimetype = getMimeContentTypeForFile(staticFilename);
		response.setHeader(HTTPHeaderCode.CONTENT_TYPE, mimetype ~ ";charset=utf-8");

		response.setHeader(HTTPHeaderCode.ACCEPT_RANGES, "bytes");
		ulong rangeStart = 0;
		ulong rangeEnd = 0;

		if (request.headerExists(HTTPHeaderCode.RANGE))
		{
			// https://tools.ietf.org/html/rfc7233
			// Range can be in form "-\d", "\d-" or "\d-\d"
			auto range = request.header(HTTPHeaderCode.RANGE).chompPrefix("bytes=");
			auto s = range.split("-");
			
			if (s.length != 2)
			{
				throw new Exception("bad request.");
			}

			try
			{
				if (s[0].length)
				{
					rangeStart = s[0].to!ulong;
					rangeEnd = s[1].length ? s[1].to!ulong : fi.size;
				}
				else if (s[1].length)
				{
					rangeEnd = fi.size;
					auto len = s[1].to!ulong;
					
					if (len >= rangeEnd)
					{
						rangeStart = 0;
					}
					else
					{
						rangeStart = rangeEnd - len;
					}
				}
				else
				{
					throw new Exception("bad request");
				}
			}
			catch (ConvException e)
			{
				throw new Exception("bad request." ~ e.msg);
			}
			
			if (rangeEnd > fi.size)
			{
				rangeEnd = fi.size;
			}
			
			if (rangeStart > rangeEnd)
			{
				rangeStart = rangeEnd;
			}
			
			if (rangeEnd)
			{
				rangeEnd--; // End is inclusive, so one less than length
			}
			// potential integer overflow with rangeEnd - rangeStart == size_t.max is intended. This only happens with empty files, the + 1 will then put it back to 0
			
			response.setHeader(HTTPHeaderCode.CONTENT_LENGTH, to!string(rangeEnd - rangeStart + 1));
			response.setHeader(HTTPHeaderCode.CONTENT_RANGE, "bytes %s-%s/%s".format(rangeStart < rangeEnd ? rangeStart : rangeEnd, rangeEnd, fi.size));
			response.setStatus(HttpStatusCodes.PARTIAL_CONTENT);
		}
		else
		{
			rangeEnd = fi.size - 1;
			response.setHeader(HTTPHeaderCode.CONTENT_LENGTH, fi.size.to!string);
		}
		
		// write out the file contents
		auto f = std.stdio.File(staticFilename, "r");
		scope(exit) f.close();
	
		f.seek(rangeStart);
		auto buf = f.rawRead(new ubyte[rangeEnd.to!uint - rangeStart.to!uint + 1]);
		response.setContent(buf);

		return response;
    }
    
    private string mendPath(string path)
    {
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
    	
    	return path ~ chompPrefix(request.path, request.route.getPattern());
    }

	private struct FileInfo {
		string name;
		ulong size;
		SysTime timeModified;
		SysTime timeCreated;
		bool isSymlink;
		bool isDirectory;
	}
	
	private FileInfo makeFileInfo(string fileName)
	{
		FileInfo fi;
		fi.name = baseName(fileName);
		auto ent = DirEntry(fileName);
		fi.size = ent.size;
		fi.timeModified = ent.timeLastModified;
		version(Windows) fi.timeCreated = ent.timeCreated;
		else fi.timeCreated = ent.timeLastModified;
		fi.isSymlink = ent.isSymlink;
		fi.isDirectory = ent.isDir;
		
		return fi;
	}
	
	private bool isCompressedFormat(string mimetype)
	{
		switch (mimetype)
		{
			case "application/gzip", "application/x-compress", "application/png", "application/zip",
					"audio/x-mpeg", "image/png", "image/jpeg",
					"video/mpeg", "video/quicktime", "video/x-msvideo",
					"application/font-woff", "application/x-font-woff", "font/woff":
				return true;
			default: return false;
		}
	}
}
