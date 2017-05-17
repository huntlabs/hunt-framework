module hunt.init;

import std.path : buildPath;
import std.file : thisExePath;

__gshared string APP_PATH;

__gshared string  DEFAULT_CONFIG_PATH = "config/";

__gshared string  DEFAULT_RESOURCE_PATH = "resources/";

__gshared string  DEFAULT_PUBLIC_PATH = "public/";

__gshared string  DEFAULT_STORAGE_PATH = "storage/";

shared static this()
{
    APP_PATH = thisExePath();
    DEFAULT_CONFIG_PATH = buildPath(APP_PATH, DEFAULT_CONFIG_PATH);
    DEFAULT_RESOURCE_PATH = buildPath(APP_PATH, DEFAULT_RESOURCE_PATH);
    DEFAULT_PUBLIC_PATH = buildPath(APP_PATH, DEFAULT_PUBLIC_PATH);
    DEFAULT_STORAGE_PATH = buildPath(APP_PATH, DEFAULT_STORAGE_PATH);
}
