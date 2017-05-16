module hunt.storage.impl.redis;

import std.conv;
import std.stdio;
import std.experimental.logger;

import hunt.storage.base;
public import hunt.storage.driver.redis;

version(USE_REDIS)
{
    class Redis : StorageInterface 
    {
        private int _expire = 3600 * 24 * 365;
        auto opDispatch(string name,T...)(T args)
        {
            auto result =  RedisInstance.send(name,args);
            return result;
        }
        bool set(string key, ubyte[] value)
        {
            return set(key,value,_expire);
        }
        bool set(string key, ubyte[] value, int expire)
        {
            return RedisInstance.set(key,cast(string)value,expire);
        }

        bool set(string key,string value)
        {
            return set(key,value,_expire);    
        }
        bool set(string key,string value,int expire)
        {
            return RedisInstance.set(key,value,expire);    
        }

        T get(T)(string key)
        {
            return cast(T)RedisInstance.get(key);
        }
        string get(string key)
        {
            return RedisInstance.get(key);
        }

        bool isset(string key)
        {
            return RedisInstance.exists(key);
        }

        bool erase(string key)
        {
            return cast(bool)RedisInstance.del(key);
        }

        bool flush()
        {
            RedisInstance.flushall();
            return true;
        }

        void setExpire(int expire)
        {
            this._expire = expire;
        }
        void setDefaultHost(string host , ushort port)
        {
            RedisInstance.setDefaultHost(host,port);
        }
    }
}
