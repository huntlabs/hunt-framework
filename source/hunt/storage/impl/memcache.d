module hunt.storage.impl.memcache;

import std.conv;

import hunt.storage.base;
import driverMemcache = hunt.storage.driver.memcache;
import std.experimental.logger;

version(USE_MEMCACHE)
{
    class Memcache : StorageInterface 
    {
        private int _expire = 3600 * 24 * 365;
        auto opDispatch(string name,T...)(T args)
        {
            mixin(`auto result =  driverMemcache.MemcacheInstance.`~name~`(args);
            return result;`);
        }
        bool set(string key, ubyte[] value, int expire)
        {
            return set(key,cast(string)value,expire);
        }

        bool set(string key,string value,int expire)
        {
            return driverMemcache.MemcacheInstance.set(key,value,expire);    
        }
        
        bool set(string key, ubyte[] value)
        {
            return set(key,value,_expire);
        }

        bool set(string key,string value)
        {
            return set(key,value,_expire);    
        }

        string get(string key)
        {
            return cast(string)driverMemcache.MemcacheInstance.get(key);
        }

        T get(T)(string key)
        {
            return cast(T)driverMemcache.MemcacheInstance.get(key);
        }

        bool isset(string key)
        {
            return cast(bool)(get(key).length);    
        }

        bool erase(string key)
        {
            return driverMemcache.MemcacheInstance.del(key);
        }

        bool flush()
        {
            return driverMemcache.MemcacheInstance.flush();
        }

        void setExpire(int expire)
        {
            this._expire = expire;
        }
        void setDefaultHost(string host, ushort port)
        {
            driverMemcache.setDefaultHost(host,port);
        }
    }
}
