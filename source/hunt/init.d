/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.init;

public import hunt.versions;

import std.path : buildPath, dirName;
import std.file : thisExePath;

__gshared string APP_PATH;
__gshared string DEFAULT_CONFIG_PATH = "config/";
__gshared string DEFAULT_LANGUAGE_PATH = "resources/languages";
__gshared string DEFAULT_PUBLIC_PATH = "public/";
__gshared string DEFAULT_STORAGE_PATH = "storage/";
__gshared string DEFAULT_LOG_PATH = "logs/";
__gshared string DEFAULT_SESSION_PATH = "session/";
__gshared string DEFAULT_Download_Path = "downloads/";
__gshared string DEFAULT_Views_Path = "views/";
__gshared string DEFAULT_WWW_Root = "wwwroot/";

shared static this()
{
    APP_PATH = dirName(thisExePath());
    DEFAULT_CONFIG_PATH = buildPath(APP_PATH, DEFAULT_CONFIG_PATH);
    DEFAULT_LANGUAGE_PATH = buildPath(APP_PATH, DEFAULT_LANGUAGE_PATH);
    DEFAULT_PUBLIC_PATH = buildPath(APP_PATH, DEFAULT_PUBLIC_PATH);
    DEFAULT_STORAGE_PATH = buildPath(APP_PATH, DEFAULT_STORAGE_PATH);
    DEFAULT_LOG_PATH = buildPath(DEFAULT_STORAGE_PATH, DEFAULT_LOG_PATH);
    DEFAULT_SESSION_PATH = buildPath(DEFAULT_STORAGE_PATH, DEFAULT_SESSION_PATH);
    
    DEFAULT_Download_Path = buildPath(APP_PATH, DEFAULT_Download_Path);
    DEFAULT_WWW_Root = buildPath(APP_PATH, DEFAULT_WWW_Root);
    DEFAULT_Views_Path = buildPath(APP_PATH, DEFAULT_Views_Path);
}
