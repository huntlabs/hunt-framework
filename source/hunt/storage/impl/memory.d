module hunt.storage.impl.memory;

import std.conv;

import hunt.storage.base;
import hunt.storage.driver.memory;

class Memory : StorageInterface
{
    private int _expire;
    bool set(string key, ubyte[] value, int expire )
    {
        return MemoryInstance.set(key,value);    
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
        return MemoryInstance.get(key);    
    }

    T get(T)(string key)
    {
        return cast(T)get(key);
    }

    bool isset(string key)
    {
        return MemoryInstance.isset(key);    
    }

    bool erase(string key)
    {
        return MemoryInstance.erase(key);    
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
