module hunt.storage.impl.file;

import std.conv;

import hunt.storage.base;
import hunt.storage.driver.file;

class File : StorageInterface
{
    private int _expire;
    bool set(string key, ubyte[] value, int expire )
    {
        return FileInstance.set(key,value);    
    }
    
    bool set(string key, ubyte[] value)
    {
        return set(key,value,_expire);
    }
    
    bool set(string key,string value,int expire)
    {
        return set(key,cast(ubyte[])value,expire);
    }
    
    bool set(string key,string value)
    {
        return set(key,cast(ubyte[])value,_expire);
    }

    string get(string key)
    {
        return FileInstance.get(key);    
    }

    T get(T)(string key)
    {
        return cast(T)get(key);
    }

    bool isset(string key)
    {
        return FileInstance.isset(key);    
    }

    bool erase(string key)
    {
        return FileInstance.erase(key);    
    }

    bool flush()
    {
        return true;
    }

    void setExpire(int expire)
    {
        this._expire = expire;
    }

    void setDefaultHost(string host, ushort port)
    {
    
    }
}                
