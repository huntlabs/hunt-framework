module hunt.view.cache;

import std.stdio;
import std.array;
import std.string;
import core.sync.rwmutex;
import std.digest.sha;
import std.digest.md;
import hunt.view.ast;

class ASTCacheManager
{

    ASTNode node(string path)
    {
        synchronized (_mutex.reader)
        {
            // writeln("----cache hit ast node : ",path);
            return _astMap.get(path, null);
        }

    }

    void add(string path, ASTNode node)
    {
        _mutex.writer.lock();
        scope (exit)
            _mutex.writer.unlock();

        auto ast = _astMap.get(path, null);
        if (ast is null)
        {
            //writeln("add cache : ",path," key : ",path," cache size: ",_astMap.length);
            _astMap[path] = node;
        }

        // writeln(" cache keys : ",_astMap.keys);
    }

private:
    this()
    {
        _mutex = new ReadWriteMutex();
    }

    ~this()
    {
        _mutex.destroy;
    }

    ASTNode[string] _astMap;

    ReadWriteMutex _mutex;
}

@property ASTCacheManager ASTCache()
{
    return _astcache;
}

shared static this()
{
    //writeln("#######rrt");
    _astcache = new ASTCacheManager();
}

private:
__gshared ASTCacheManager _astcache;
