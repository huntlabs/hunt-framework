module hunt.storage.impl.memcache;

import std.conv;

import hunt.storage.driver.memcache;

version(USE_MEMCACHE)
{
    class Memcache : AbstractCache 
    {
        private int _expire = 3600 * 24 * 365;
        auto opDispatch(string name,T...)(T args)
        {
            mixin(`auto result =  MemcacheInstance.`~name~`(args);
            return result;`);
        }
        bool set(string key, ubyte[] value, int expire)
        {
            return set(key,value.to!string,expire);
        }

        bool set(string key,string value,int expire)
        {
            return MemcacheInstance.Memcache.set(key,value,expire);    
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
            return cast(string)MemcacheInstance.Memcache.get(key);
        }

        T get(T)(string key)
        {
            return cast(T)MemcacheInstance.Memcache.get(key);
        }

        bool isset(string key)
        {
            return cast(bool)(get(key).length);    
        }

        bool erase(string key)
        {
            return MemcacheInstance.Memcache.del(key);
        }

        bool flush()
        {
            return MemcacheInstance.Memcache.flush();
        }

        void setExpire(int expire)
        {
            this._expire = expire;
        }
        void setDefaultHost(string host, ushort port)
        {
            MemcacheInstance.setDefaultHost(host,port);
        }
    }
}
