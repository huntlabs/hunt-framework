module hunt.framework.http.DownloadResponse;

import std.array;
import std.conv;
import std.datetime;
import std.json;
import std.path;
import std.file;
import std.stdio;

import hunt.framework.init;
import hunt.framework.application.AppConfig;
// import hunt.framework.http.cookie;
import hunt.framework.utils.string;
import hunt.framework.versions;
import hunt.framework.http.Response;
import hunt.framework.http.Request;

import hunt.logging;
import hunt.http.codec.http.model.HttpHeader;

/**
 * DownloadResponse represents an HTTP response delivering a file.
 */
class DownloadResponse : Response
{
    private string fileName;

    this(Request request, string fileName, string contentType = OctetStreamContentType)
    {
        super(request);
        
        setHeader(HttpHeader.CONTENT_TYPE, contentType);
        this.fileName = fileName;
    }

    DownloadResponse loadData()
    {
        string fullName = buildPath(APP_PATH, Config.app.download.path, fileName);

        logDebug("downloading file: ", fullName);
        if(exists(fullName) && !isDir(fullName))
        {
            // setData([0x11, 0x22]);
            // FIXME: Needing refactor or cleanup -@zxp at 5/24/2018, 6:49:23 PM
            // download a huge file.
            // read file
            auto f = std.stdio.File(fullName, "r");
            scope(exit) f.close();
        
            f.seek(0);
            // logDebug("file size: ", f.size);
            auto buf = f.rawRead(new ubyte[cast(uint)f.size]);
            setData(buf);
        }
        else
            throw new Exception("File does not exist: " ~ fileName);

        return this;
    }


    DownloadResponse setData(in ubyte[] data)
    {
        setHeader(HttpHeader.CONTENT_DISPOSITION, "attachment; filename=" ~ baseName(fileName) ~ "; size=" ~ (to!string(data.length)));

        setContent(data);
        return this;
    }
}
