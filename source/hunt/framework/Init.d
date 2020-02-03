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

module hunt.framework.Init;

public import hunt.framework.Version;

import std.path : buildPath, dirName;
import std.file : thisExePath;

__gshared string APP_PATH;
__gshared string DEFAULT_CONFIG_PATH = "config/";
__gshared string DEFAULT_RESOURCE_PATH = "resources/";
__gshared string DEFAULT_TEMPLATE_PATH = "views/";
__gshared string DEFAULT_LANGUAGE_PATH = "translations/";
__gshared string DEFAULT_PUBLIC_PATH = "public/";
__gshared string DEFAULT_STORAGE_PATH = "storage/";
__gshared string DEFAULT_TEMP_PATH = "tmp/";
__gshared string DEFAULT_LOG_PATH = "logs/";
__gshared string DEFAULT_SESSION_PATH = "session/";


enum string DEFAULT_CONFIG_LACATION = "config/";
enum string DEFAULT_STATIC_FILES_LACATION = "wwwroot/";

enum string DEFAULT_CONFIG_FILE = "application.conf";
enum string DEFAULT_ROUTE_CONFIG = "./routes";

// default route group name
enum string DEFAULT_ROUTE_GROUP = "default";
enum string ROUTE_CONFIG_EXT = ".routes";


shared static this()
{
    APP_PATH = dirName(thisExePath());
    DEFAULT_CONFIG_PATH = buildPath(APP_PATH, DEFAULT_CONFIG_LACATION);
    DEFAULT_RESOURCE_PATH = buildPath(APP_PATH, DEFAULT_RESOURCE_PATH);
    DEFAULT_TEMPLATE_PATH = buildPath(DEFAULT_RESOURCE_PATH, DEFAULT_TEMPLATE_PATH);
    DEFAULT_LANGUAGE_PATH = buildPath(DEFAULT_RESOURCE_PATH, DEFAULT_LANGUAGE_PATH);
    DEFAULT_PUBLIC_PATH = buildPath(APP_PATH, DEFAULT_PUBLIC_PATH);
    DEFAULT_STORAGE_PATH = buildPath(APP_PATH, DEFAULT_STORAGE_PATH);
    DEFAULT_TEMP_PATH = buildPath(DEFAULT_STORAGE_PATH, DEFAULT_TEMP_PATH);
    DEFAULT_LOG_PATH = buildPath(DEFAULT_STORAGE_PATH, DEFAULT_LOG_PATH);
    DEFAULT_SESSION_PATH = buildPath(DEFAULT_STORAGE_PATH, DEFAULT_SESSION_PATH);
}
