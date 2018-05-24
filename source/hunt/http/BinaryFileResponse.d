module hunt.http.BinaryFileResponse;

import std.array;
import std.conv;
import std.datetime;
import std.json;
import std.path;
import std.file;

import collie.codec.http.headers.httpcommonheaders;
import collie.codec.http.server.responsehandler;
import collie.codec.http.server.responsebuilder;
import collie.codec.http.httpmessage;
import kiss.logger;

import hunt.init;
import hunt.application.config;
import hunt.http.cookie;
import hunt.utils.string;
import hunt.versions;
import hunt.http.response;

/**
 * BinaryFileResponse represents an HTTP response delivering a file.
 */
class BinaryFileResponse : Response
{
    private string fileName;

    this(string fileName, string contentType = OctetStreamContentType)
    {
        super();
        setHeader(HTTPHeaderCode.CONTENT_TYPE, contentType);
        this.fileName = fileName;
    }

    BinaryFileResponse loadData()
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
            auto buf = f.rawRead(new ubyte[f.size]);
            setData(buf);
        }
        else
            throw new Exception("File does not exist: " ~ fileName);
        return this;
    }


    BinaryFileResponse setData(in ubyte[] data)
    {
        setHeader(HTTPHeaderCode.CONTENT_DISPOSITION,
                "attachment; filename=" ~ baseName(fileName) ~ "; size=" ~ (to!string(data.length)));
        setContent(data);
        return this;
    }


}
