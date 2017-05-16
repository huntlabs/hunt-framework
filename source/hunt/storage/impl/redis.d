module hunt.storage.impl.redis;

import std.conv;
import std.stdio;
import std.experimental.logger;

import hunt.storage;

public import driverRedis = hunt.storage.driver.redis;

version(USE_REDIS)
{
    class Redis : AbstractCache 
    {
        private int _expire = 3600 * 24 * 365;
        auto opDispatch(string name,T...)(T args)
        {
            auto result =  driverRedis.Redis.send(name,args);
            return result;
        }
        bool set(string key, ubyte[] value)
        {
            return set(key,value,_expire);
        }
        bool set(string key, ubyte[] value, int expire)
        {
            return driverRedis.Redis.set(key,cast(string)value,expire);
        }

        bool set(string key,string value)
        {
            return set(key,value,_expire);    
        }
        bool set(string key,string value,int expire)
        {
            return driverRedis.Redis.set(key,value,expire);    
        }

        T get(T)(string key)
        {
            return cast(T)driverRedis.Redis.get(key);
        }
        string get(string key)
        {
            return driverRedis.Redis.get(key);
        }

        bool isset(string key)
        {
            return driverRedis.Redis.exists(key);
        }

        bool erase(string key)
        {
            return cast(bool)driverRedis.Redis.del(key);
        }

        bool flush()
        {
            driverRedis.Redis.flushall();
            return true;
        }

        void setExpire(int expire)
        {
            this._expire = expire;
        }
        void setDefaultHost(string host , ushort port)
        {
            driverRedis.setDefaultHost(host,port);
        }
    }
}
