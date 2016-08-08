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

import std.experimental.logger;

enum ubyte[2] ENDMYITLFORM = ['-','-']; 

class WebForm
{
	alias StringArray = string[];
    final class FormFile
    {
        string fileName;
        string contentType;
        ulong startSize = 0;
        ulong length = 0;
		ubyte[] data;
	private : 
		this(){}
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

	@property StringArray[string] formMap()
    {
        return _forms;
    }

    @property FormFile[string] fileMap()
    {
        return _files;
    }

    string getFromValue(string key)
    {
		StringArray aty;
		aty = _forms.get(key, aty);
		if(aty.length == 0)
			return "";
		else
			return aty[0];
    }

    StringArray getFromValueArray(string key)
    {
            StringArray aty;
            return _forms.get(key, aty);
    }

    auto getFileValue(string key) const
    {
      return   _files.get(key, null);
    }

protected:
    void readXform(SectionBuffer buffer)
    {
        ubyte[] buf = new ubyte[buffer.length];
        buffer.read(buf);
        parseFromKeyValues(cast(string) buf);
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
			import std.array;
            FormFile fp = new FormFile;
            fp.fileName = filename;
            fp.contentType = header.get("content-type", "");
            fp.startSize = buffer.readSize();
			auto value = appender!(ubyte[])();

            buffer.readUtil(boundary, delegate(in ubyte[] rdata) {
                fp.length += rdata.length;
					value.put(rdata);
            });
			fp.data = value.data;
            _files[name] = fp;
        }
        else
        {
            import std.array;
            auto value = appender!(string)();
            buffer.readUtil(boundary, delegate(in ubyte[] rdata) {
		value.put(cast(string) rdata);
            });
            string stdr = value.data;
            _forms[name] ~= stdr;

        }
        ubyte[2] ub;
        buffer.read(ub);
        if (ub == ENDMYITLFORM)
        {
            return false;
        }
        enforce(ub == cast(ubyte[]) "\r\n", "showed be \\r\\n");
        return true;
    }

	void parseFromKeyValues(string raw, string split1 = "&", string spilt2 = "=")
	{
            import std.uri;
            if (raw.length == 0)
                    return ;
            string[] pairs = raw.strip.split(split1);
            foreach (string pair; pairs)
            {
                    string[] parts = pair.split(spilt2);
                    
                    // Accept formats a=b/a=b=c=d/a
                    if (parts.length == 1)
                    {
                            string key = parts[0];
                            _forms[key] ~= "";
                    }
                    else if (parts.length > 1)
                    {
                            string key = parts[0];
                            string value = pair[parts[0].length + 1 .. $];
                            _forms[key] ~= decodeComponent(value);
                    }
            }
	}
private:
    bool _vaild = true;
    StringArray[string] _forms;
    FormFile[string] _files;
}
