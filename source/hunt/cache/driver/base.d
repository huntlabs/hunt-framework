module hunt.cache.driver.base;

import std.conv : to;

abstract class AbstractCache
{
    public
    {
        bool set(string key, ubyte[] value, int expire = 0);

        ubyte[] get(string key);

        bool isset(string key);

        bool erase(string key);

        bool flush();

        void setExpire(int expire)
        {
            this._expire = expire;
        }
    }

    protected
    {
        int _expire;
    }
}
