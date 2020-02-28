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

public import hunt.framework.application.Application : app;
public import hunt.framework.application.ApplicationConfig : ApplicationConfig;
public import hunt.util.DateTime : time, date;
public import hunt.framework.Init;
import hunt.framework.provider;

import hunt.logging.ConsoleLogger;

import poodinis;

import std.array;
import std.string;
import std.json;

ApplicationConfig config()
{
    // return configManager().config();
    return serviceContainer().resolve!(ApplicationConfig);
}

string url(string mca) {
    return url(mca, null);
}

string url(string mca, string[string] params, string group) {
    return app().createUrl(mca, params, group);
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

    return app().createUrl(pathItem, params, group);
}

public import hunt.entity.EntityManager;
public import hunt.entity.DefaultEntityManagerFactory;

//global entity manager
private EntityManager _em;
EntityManager defaultEntityManager()
{
    if (_em is null)
    {
        _em = defaultEntityManagerFactory().currentEntityManager();
    }
    return _em;
}


//close global entity manager
void closeDefaultEntityManager()
{
    version(WITH_HUNT_ENTITY)  {
        if(_em !is null)
        {
            _em.close();
            _em = null;
        }
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
    version(HUNT_DEBUG) tracef("format string: %s, key: %s, args.length: ", text, key, args.length);
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
    logWarning("unsupported locale: ", locale, ", use default now: ", i18n.defaultLocale);

    p = i18n.defaultLocale in i18n.resources;

    if (p !is null) {
        return p.get(key, defaultValue);
    }

    logDebug("unsupported locale: ", i18n.defaultLocale);

    return defaultValue;
}