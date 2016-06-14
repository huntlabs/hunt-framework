/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */
module hunt.http.webfrom;

import collie.codec.http;
import collie.buffer;

import std.string;
import std.exception;

class WebForm
{
    final class FormFile
    {
        string fileName;
        string contentType;
        ulong startSize = 0;
        ulong length = 0;
    }

    this(HTTPRequest req)
    {
        string type = req.Header.getHeaderValue("Content-Type");
        if (type.indexOf("multipart/form-data") > -1)
        {
            auto tmp = parseKeyValues(type, "; ");
            auto strBoundary = tmp.get("boundary", "").strip();
            if (strBoundary.length > 0)
            {
                readMultiFrom(strBoundary, req.Body);
            }
        }
        else if (type.indexOf("application/x-www-form-urlencoded") > -1)
        {
            readXform(req.Body);
        }
        else
        {
            _vaild = false;
        }
    }

    @property bool isVaild() const
    {
        return _vaild;
    }

    @property string[string] formMap()
    {
        return _forms;
    }

    @property FormFile[string] fileMap()
    {
        return _files;
    }

    string getFromValue(string key) const
    {
        return _forms.get(key, "");
    }

    auto getFileValue(string key) const
    {
        _files.get(key, null);
    }

protected:
    void readXform(SectionBuffer buffer)
    {
        ubyte[] buf = new ubyte[buffer.length];
        buffer.read(buf);
        _forms = parseKeyValues(cast(string) buf);
    }

    void readMultiFrom(string brand, SectionBuffer buffer)
    {
        buffer.rest();
        string brony = "--" ~ brand;
        auto sttr = buffer.readLine();
        if (!((cast(string) sttr) == brony))
            return;
        brony = "\r\n" ~ brony;
        bool run;
        do
        {
            run = readMultiftomPart(buffer, cast(ubyte[]) brony);
        }
        while (run);
    }

    bool readMultiftomPart(SectionBuffer buffer, ubyte[] boundary)
    {
        ubyte[] line = buffer.readLine();
        string[string] header; // = new string[string];
        while (line.length > 0)
        { //遇到空的换行符结束
            auto pos = (cast(string) line).indexOf(":");
            if (pos <= 0 || pos == (line.length - 1))
                continue;
            string key = cast(string)(line[0 .. pos]);
            header[toLower(key.strip)] = (cast(string)(line[pos + 1 .. $])).strip;
            line = buffer.readLine();
        }
        /*if("content-disposition" !in header){
		return false;
		}*/
        string cd = header.get("content-disposition", "");
        if (cd.length == 0)
            return false;
        string name;
        auto pos = cd.indexOf("name=\"");
        if (pos >= 0)
        {
            cd = cd[pos + 6 .. $];
            pos = cd.indexOf("\"");
            name = cd[0 .. pos];
        }
        string filename;
        pos = cd.indexOf("filename=\"");
        if (pos >= 0)
        {
            cd = cd[pos + 10 .. $];
            pos = cd.indexOf("\"");
            filename = cd[0 .. pos];
        }
        if (filename.length > 0)
        {
            FormFile fp = new FormFile;
            fp.fileName = filename;
            fp.contentType = header.get("content-type", "");
            fp.startSize = buffer.readSize();
            buffer.readUtil(boundary, delegate(in ubyte[] rdata) {
                fp.length += rdata.length;
            });
            _files[name] = fp;
        }
        else
        {
            string value;
            buffer.readUtil(boundary, delegate(in ubyte[] rdata) {
                value ~= cast(string) rdata;
            });
            _forms[name] = value;
        }
        ubyte[2] ub;
        buffer.read(ub);
        if (ub == "--")
        {
            return false;
        }
        enforce(ub == cast(ubyte[]) "\r\n");
        return true;
    }

private:
    bool _vaild = true;
    string[string] _forms;
    FormFile[string] _files;
}
