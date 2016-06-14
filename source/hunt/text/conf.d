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
 
module hunt.text.conf;

import std.array;
//import std.file;
import std.stdio;
import std.string;

class Conf
{
    this()
    {}
    
    this(string file){_fileName = file;}
    
    
protected:
    void readConf()
    {
        import std.format;
        auto f = File(_fileName,"r");
        if(_element)
        {
            _element.destroy;
        }
        _element = new Element();
        Element ele = _element;
        int line = 1;
        uint level = 0;
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
                string[] list = split(str[1..len],'.');
                ele = getElement(list);
                continue;
            }
            auto site = str.indexOf("=");
            if(site == -1)
                throw new Exception(format("the format is erro in file %s, in line %d",_fileName,line));
            
        }
    }
    
    
    Element getElement(in string[] list)
    {
        Element ele = _element;
        foreach (ref str ; list)
        {
            if(str.length == 0) continue;
        }
        return ele;
    }
private:
    string _fileName;
    Element _element; 
}

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