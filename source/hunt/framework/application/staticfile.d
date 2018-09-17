module hunt.framework.application.staticfile;

import core.time;
import std.conv;
import std.string;
import std.datetime;
import std.path;
import std.digest.md;
import std.stdio;

import hunt.logging;

import hunt.framework;
import hunt.framework.application.controller;
// import hunt.framework.application.config;
import hunt.framework.utils.string;

import hunt.http.codec.http.model.HttpHeader;
import hunt.http.codec.http.model.HttpStatus;

/**
*/
class StaticfileController : Controller
{
    mixin MakeController;
    
    @Action
    Response doStaticFile()
    {
		string currentPath = request.route.staticFilePath;
		debug logDebug("currentPath: ", currentPath);
        if (currentPath == string.init)
        {
			currentPath = Config.app.http.path;
        }

        string staticFilename = mendPath(currentPath);
		debug logDebug ("staticFilename: ", staticFilename);

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
			isFileExisted = false;
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
    
        response.setHeader(HttpHeader.LAST_MODIFIED, lastModified);
        response.setHeader(HttpHeader.ETAG, etag);

        if (Config.app.application.staticFileCacheMinutes > 0)
		{
            auto expireTime = Clock.currTime(UTC()) + dur!"minutes"(Config.app.application.staticFileCacheMinutes);
            response.setHeader(HttpHeader.EXPIRES, toRFC822DateTimeString(expireTime));
            response.setHeader(HttpHeader.CACHE_CONTROL, "max-age=" ~ to!string(Config.app.application.staticFileCacheMinutes * 60));
        }

        if ((request.headerExists(HttpHeader.IF_MODIFIED_SINCE) && (request.header(HttpHeader.IF_MODIFIED_SINCE) == lastModified)) ||
            (request.headerExists(HttpHeader.IF_NONE_MATCH) && (request.header(HttpHeader.IF_NONE_MATCH) == etag)))
        {
                response.setStatus(HttpStatus.NOT_MODIFIED_304);
                return response;
		}
	
		auto mimetype = getMimeContentTypeForFile(staticFilename);
		response.setHeader(HttpHeader.CONTENT_TYPE, mimetype ~ ";charset=utf-8");

		response.setHeader(HttpHeader.ACCEPT_RANGES, "bytes");
		ulong rangeStart = 0;
		ulong rangeEnd = 0;

		if (request.headerExists(HttpHeader.RANGE))
		{
			// https://tools.ietf.org/html/rfc7233
			// Range can be in form "-\d", "\d-" or "\d-\d"
			auto range = request.header(HttpHeader.RANGE).chompPrefix("bytes=");
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
			
			response.setHeader(HttpHeader.CONTENT_LENGTH, to!string(rangeEnd - rangeStart + 1));
			response.setHeader(HttpHeader.CONTENT_RANGE, "bytes %s-%s/%s".format(rangeStart < rangeEnd ? rangeStart : rangeEnd, rangeEnd, fi.size));
			response.setStatus(HttpStatus.PARTIAL_CONTENT_206);
		}
		else
		{
			rangeEnd = fi.size - 1;
			response.setHeader(HttpHeader.CONTENT_LENGTH, fi.size.to!string);
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
    		if (!path.startsWith("/"))
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
