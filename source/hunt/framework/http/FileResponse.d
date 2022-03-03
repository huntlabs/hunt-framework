module hunt.framework.http.FileResponse;

import std.array;
import std.conv;
import std.datetime;
import std.json;
import std.path;
import std.file;
import std.stdio;

import hunt.framework.http.Response;
import hunt.framework.Init;
import hunt.framework.util.String;

import hunt.logging.Logger;
import hunt.http.server;

/**
 * FileResponse represents an HTTP response delivering a file.
 */
class FileResponse : Response {
    private string _file;
    private string _name = "undefined.file";
    private string _contentType;

    this(string filename) {
        this.setFile(filename);
    }

    FileResponse setFile(string filename) {
        _file = buildPath(APP_PATH, filename);
        string contentType = getMimeTypeByFilename(_file);

        version(HUNT_DEBUG) logInfof("_file=>%s, contentType=%s", _file, contentType);

        this.setMimeType(contentType);
        this.setName(baseName(filename));
        this.loadData();
        return this;
    }

    FileResponse setName(string name) {
        _name = name;
        return this;
    }

    FileResponse setMimeType(string contentType) {
        _contentType = contentType;
        return this;
    }

    FileResponse loadData() {
        version(HUNT_DEBUG) logDebug("downloading file: ", _file);

        if (exists(_file) && !isDir(_file)) {
            // setData([0x11, 0x22]);
            // FIXME: Needing refactor or cleanup -@zxp at 5/24/2018, 6:49:23 PM
            // download a huge file.
            // read file
            auto f = std.stdio.File(_file, "r");
            scope (exit)
                f.close();

            f.seek(0);
            // logDebug("file size: ", f.size);
            auto buf = f.rawRead(new ubyte[cast(uint) f.size]);
            setData(buf);
        } else
            throw new Exception("File does not exist: " ~ _file);

        return this;
    }

    FileResponse setData(in ubyte[] data) {
        header(HttpHeader.CONTENT_DISPOSITION,
                "attachment; filename=" ~ _name ~ "; size=" ~ (to!string(data.length)));
        setContent(data, _contentType);
        return this;
    }
}
