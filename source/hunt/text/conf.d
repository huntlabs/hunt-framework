/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.text.conf;

import std.array;
import std.stdio;
import std.string;
import std.exception;

class INIFormatExceptionException : Exception
{
	mixin basicExceptionCtors;
}

class Ini
{
    this()
    {}
    
    this(string file)
    {
        setConfigFile(file);
    }
    
    //pragma(inline, true)
    void setConfigFile(string file)
    {
        _fileName = file;
        readConf();
    }
    
    auto get(T = string)(string path, T def = T.init)
    {
        import std.conv;
        string str = _element.getValue(path);
        if(str.length == 0)
            return def;
        else
            return to!T(str);
    }
    
    bool set(T)(string path, T value)
    {
        import std.conv;
        if(path.length == 0) return false;
        string[] list = split(path,'.');
        size_t len = list.length - 1;
        auto ele  = getElement(list[0..len]);
        string key = list[len];
        if(key.length == 0) return false;
        ele.values[key] = to!string(value);
        return true;
    }
    
    pragma(inline, true)
    bool save()
    {
        return saveToFile(_fileName);
    }
    
    pragma(inline, true)
    bool saveAs(string fileName)
    {
        return saveToFile(fileName);
    }
    
protected:
    void readConf()
    {
        auto f = File(_fileName,"r");
        if(_element)
        {
            _element.destroy;
        }
        _element = new Element();
        if(!f.isOpen()) return;
		scope(exit) f.close();
        Element ele = _element;
        int line = 1;
        while(!f.eof())
        {
            scope(exit) line += 1;
            string str = f.readln();
            str = strip(str);
            if(str.length == 0) continue;
            if(str[0] == '#' || str[0] == ';') continue;
            auto len = str.length -1;
            if(str[0] == '[' && str[len] == ']')
            {
                string section = str[1..len].strip;
                string[] list = split(section,'.');
                ele = getElement(list);
                continue;
            }
            auto site = str.indexOf("=");
			enforce!INIFormatExceptionException((site > 0),format("the format is erro in file %s, in line %d",_fileName,line));
            string key = str[0..site].strip;
            string value  = str[site + 1..$].strip;
            ele.values[key] = value;
        }
    }
    
    
    Element getElement(in string[] list)
    {
        Element ele = _element;
        size_t num = 1;
        foreach (ref str ; list)
        {
            scope(exit) num += 1;
            if(str.length == 0) continue;
            auto tele = ele.elements.get(str, null);
            if(tele is null)
            {
                tele = new Element;
                tele.path = list[0..num].join('.');
                ele.elements[str] = tele;
            }
            ele = tele;
        }
        return ele;
    }
    
    bool saveToFile(string file)
    {
        if(file.length == 0) return false;
        auto f = File(file,"w");
        if(!f.isOpen()) return false;
        writeElement(&f,_element);
        return true;
    }
    
    void writeElement(File * file, Element ele)
    {
        if(ele.path.length > 0)
        {
            file.writeln(format(";The section = %s",ele.path));
            file.writefln("[%s]",ele.path);
        }
        
        foreach(key,value; ele.values)
        {
            file.writefln("%s = %s",key,value);
        }
        file.writeln("");
        foreach(_,value; ele.elements)
        {
            writeElement(file,value);
        }
    }
    
private:
    string _fileName;
    Element _element; 
}

alias Conf = Ini;

private:
final class Element
{
    string[string] values;
    
    Element[string] elements;
    
    string path;
    
    string getValue(string key)
    {
        if(key.length == 0) return string.init;
        string[] list = split(key,'.');
        size_t len = list.length - 1;
        Element ele = this;
        for (size_t i = 0; i < len; ++i)
        {
            auto element = ele.elements.get(list[i], null);
            if (element is null )  return string.init;
            ele = element;
        }
        return ele.values.get(list[len], string.init);
    }
} 

unittest
{
    string tbody = "[server] \nhost = 0.0.0.0 \nport = 8081 \n\n[upload_tmp_path]\ntempath = ./storage/tmp\n\n";
    tbody ~= "[route] \npath = ./config/router.conf \n\n[log]  \nname = error,fatal,info\n\n[file_path]\nfilesDir = ./uploads\n;huioiujopp\n#guijj\n\n";
    tbody ~= "[route.tmp]\npath = hujjokp\n\n";
    auto f = File("tmp.conf","w");
    f.write(tbody);
    f.close();
    Conf conf = new Conf("tmp.conf");
    string host = conf.get("server.host");
    assert(host == "0.0.0.0");
    ushort us = conf.get!ushort("server.port");
    assert(us == cast(ushort)8081);
    host = conf.get("route.tmp.path");
    assert(host == "hujjokp");
    host = conf.get("upload_tmp_path.tempath");
    assert(host == "./storage/tmp");
    conf.set("aa.bb.cc.dd", 500);
    assert(conf.saveAs("tmp.saveas.conf"));
}