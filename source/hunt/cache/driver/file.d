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

module hunt.cache.driver.file;

import std.conv;

import hunt.cache.driver.base;

import fs = hunt.storage.filestorage;

class FileCache : AbstractCache
{
    private int _expire;
    override bool set(string key, ubyte[] value, int expire )
    {
        return fs.File.set(key,value);    
    }
    
    override bool set(string key, ubyte[] value)
    {
        return set(key,value,_expire);
    }
    
    override bool set(string key,string value,int expire)
    {
        return set(key,cast(ubyte[])value,expire);
    }
    
    override bool set(string key,string value)
    {
        return set(key,cast(ubyte[])value,_expire);
    }

    override string get(string key)
    {
        return fs.File.get(key);    
    }

    T get(T)(string key)
    {
        return cast(T)get(key);
    }

    override bool isset(string key)
    {
        return fs.File.isset(key);    
    }

    override bool erase(string key)
    {
        return fs.File.erase(key);    
    }

    override bool flush()
    {
        return true;
    }

    override void setExpire(int expire)
    {
        this._expire = expire;
    }

    override void setDefaultHost(string host, ushort port)
    {
    
    }
}                
