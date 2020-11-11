/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.Simplify;

// public import hunt.framework.application.Application : app;
public import hunt.framework.config.ApplicationConfig;
public import hunt.framework.config.ConfigManager;
public import hunt.framework.Init;
public import hunt.framework.routing;
public import hunt.util.DateTime : time, date;

import hunt.framework.provider;
import hunt.logging.ConsoleLogger;
import hunt.util.TaskPool;

import poodinis;

import std.array;
import std.string;
import std.json;

ConfigManager configManager() {
    return serviceContainer().resolve!(ConfigManager);
}

ApplicationConfig config() {
    return serviceContainer().resolve!(ApplicationConfig);
}

RouteConfigManager routeConfig() {
    return serviceContainer().resolve!(RouteConfigManager);
}

string url(string mca) {
    return url(mca, null);
}


string url(string mca, string[string] params, string group) {
    return routeConfig().createUrl(mca, params, group);
}

string url(string mca, string[string] params) {
    // admin:user.user.view
    string[] items = mca.split(":");
    string group = "";
    string pathItem = "";
    if (items.length == 1) {
        group = "";
        pathItem = mca;
    } else if (items.length == 2) {
        group = items[0];
        pathItem = items[1];
    } else {
        throw new Exception("Bad format for mca");
    }

    // return app().createUrl(pathItem, params, group);
    return routeConfig().createUrl(pathItem, params, group);
}

public import hunt.entity.EntityManager;

import hunt.entity.DefaultEntityManagerFactory;
import hunt.entity.EntityManagerFactory;
import hunt.framework.application.closer.EntityCloser;
import hunt.util.Common;

version(HUNT_TEST) {
    import std.datetime;
    import std.format;
    import core.atomic;
    import core.sync.mutex;
    import core.thread ;

    import hunt.framework.http.Request;
    import hunt.util.ThreadHelper;
    import hunt.collection.ArrayList;
    import hunt.collection.ArrayList;


    class EntityManagerInfo {
        ThreadID threadId;
        int number;
        string path;
        SysTime holdUpTime;
        SysTime releaseTime;
        // string connection;

        this() {
            threadId = getTid();
            holdUpTime = Clock.currTime;
            releaseTime = holdUpTime;
            number = atomicOp!"+="(counter, 1);
            Request req = request();
            if(req is null) {
                warning("Called from a non-Controller thread.");
            } else {
                path = req.path();
            }
        }

        override string toString() {
            string str = format("%6d | %05d | %s | %s | %s | %s", 
                threadId, number, holdUpTime, releaseTime, releaseTime-holdUpTime, path);

            return str;
        }

        shared static int counter;
        __gshared EntityManagerInfo[] _entityManagers;
        __gshared Mutex _mtx;

        shared static this() {
            // entityManagers = new ArrayList!EntityManagerInfo(500);
            _mtx = new Mutex();
        }

        static void append() {
            EntityManagerInfo managerInfo = new EntityManagerInfo();
            _mtx.lock();
            scope(exit) _mtx.unlock();
            _entityManagers ~= managerInfo;

            error(managerInfo.toString());
        }

        static void remove() {
            ThreadID tid = getTid();
            
            string reqPath;
            Request req = request();
            if(req !is null)
                reqPath = req.path();

            _mtx.lock();
            scope(exit) _mtx.unlock();

            bool isRemoved = false;
            foreach(size_t index, EntityManagerInfo managerInfo; _entityManagers) {
                if(managerInfo.threadId == tid && managerInfo.path == reqPath) {
                    managerInfo.releaseTime = Clock.currTime;

                    error(managerInfo);
                    if(index == 0) {
                        _entityManagers = _entityManagers[index+1 .. $];
                    } else if(index + 1 == _entityManagers.length) {
                        _entityManagers =  _entityManagers[0 .. index];
                    } else {
                        _entityManagers =  _entityManagers[0 .. index] ~  _entityManagers[index+1 .. $];
                    }
                    isRemoved = true;
                    break;
                }

                if(!isRemoved) {
                    warningf("Nothing removed: ", tid, reqPath);
                }
            }
        }

        static string[] listAll() {
            string[] result;
            _mtx.lock();
            scope(exit) _mtx.unlock();

            foreach(EntityManagerInfo managerInfo; _entityManagers) {
                result ~= managerInfo.toString();
            }

            return result;
        }
    }


    //global entity manager
    private EntityManager _em;
    EntityManager defaultEntityManager() {
        if (_em is null) {
            _em = serviceContainer.resolve!(EntityManagerFactory).currentEntityManager();
            // resouceManager.push(new EntityCloser(_em));
            resouceManager.push(new class Closeable {
                void close() {
                    closeDefaultEntityManager();
                    EntityManagerInfo.remove();
                }
            });

            EntityManagerInfo.append();
        }
        return _em;
    }

} else {
    //global entity manager
    private EntityManager _em;
    EntityManager defaultEntityManager() {
        if (_em is null) {
            _em = serviceContainer.resolve!(EntityManagerFactory).currentEntityManager();
            // resouceManager.push(new EntityCloser(_em));
            resouceManager.push(new class Closeable {
                void close() {
                    closeDefaultEntityManager();
                }
            });
        }
        return _em;
    }
}

//close global entity manager
void closeDefaultEntityManager() {
    if (_em !is null) {
        _em.close();
        _em = null;
    }
}

// i18n
import hunt.framework.i18n.I18n;

private __gshared string _local /* = I18N_DEFAULT_LOCALE */ ;

@property string getLocale() {
    if (_local)
        return _local;
    return serviceContainer.resolve!(I18n).defaultLocale;
}

@property setLocale(string _l) {
    _local = toLower(_l);
}

string trans(A...)(string key, lazy A args) {
    import std.format;

    Appender!string buffer;
    string text = _trans(key);
    version (HUNT_DEBUG)
        tracef("format string: %s, key: %s, args.length: ", text, key, args.length);
    formattedWrite(buffer, text, args);

    return buffer.data;
}

string transWithLocale(A...)(string locale, string key, lazy A args) {
    import std.format;

    Appender!string buffer;
    string text = _transWithLocale(locale, key);
    formattedWrite(buffer, text, args);

    return buffer.data;
}

string transWithLocale(string locale, string key, JSONValue args) {
    import hunt.framework.util.Formatter;

    string text = _transWithLocale(locale, key);
    return StrFormat(text, args);
}

///key is [filename.key]
private string _trans(string key) {
    string defaultValue = key;
    I18n i18n = serviceContainer.resolve!(I18n);
    if (!i18n.isResLoaded) {
        logWarning("The lang resources haven't loaded yet!");
        return key;
    }

    auto p = getLocale in i18n.resources;
    if (p !is null) {
        return p.get(key, defaultValue);
    }
    logWarning("unsupported local: ", getLocale, ", use default now: ", i18n.defaultLocale);

    p = i18n.defaultLocale in i18n.resources;

    if (p !is null) {
        return p.get(key, defaultValue);
    }

    logWarning("unsupported locale: ", i18n.defaultLocale);

    return defaultValue;
}

///key is [filename.key]
private string _transWithLocale(string locale, string key) {
    string defaultValue = key;
    I18n i18n = serviceContainer.resolve!(I18n);
    if (!i18n.isResLoaded) {
        logWarning("The lang resources has't loaded yet!");
        return key;
    }

    auto p = locale in i18n.resources;
    if (p !is null) {
        return p.get(key, defaultValue);
    }
    version(HUNT_DEBUG) { 
        logWarning("No language resource found for ", locale, 
            ". Use the default now: ", i18n.defaultLocale);
    }

    locale = i18n.defaultLocale;
    p = locale in i18n.resources;

    if (p !is null) {
        return p.get(key, defaultValue);
    }

    warning("No language resource found for: ", locale);

    return defaultValue;
}

private bool _inWorkerThread = false;

bool inWorkerThread() {
    if(_inWorkerThread)
        return true;

    import core.thread;
    
    ParallelismThread th = cast(ParallelismThread)Thread.getThis();
    return th !is null;
}

void startWorkerThread() {
    _inWorkerThread = true;
}

void resetWorkerThread() {
    resouceManager.clean();
}

import hunt.framework.application.ResourceManager;
private ResouceManager _resouceManager;

ResouceManager resouceManager() {
    if(_resouceManager is null) {
        _resouceManager = new ResouceManager();
    }
    return _resouceManager;
}


import hunt.framework.queue;

AbstractQueue messageQueue() {
    return serviceContainer.resolve!(AbstractQueue);
}