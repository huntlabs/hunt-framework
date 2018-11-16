/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Website: www.huntframework.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.view.ASTCacheManager;

import std.stdio;
import std.array;
import std.string;
import core.sync.rwmutex;
import std.digest.sha;
import std.digest.md;
import hunt.framework.view.ASTNode;

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
