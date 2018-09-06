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

module hunt.framework.init;

public import hunt.framework.versions;

import std.path : buildPath, dirName;
import std.file : thisExePath;

__gshared string APP_PATH;
__gshared string DEFAULT_CONFIG_PATH = "config/";
__gshared string DEFAULT_TEMPLATE_PATH = "views/";
__gshared string DEFAULT_LANGUAGE_PATH = "resources/languages";
__gshared string DEFAULT_PUBLIC_PATH = "public/";
__gshared string DEFAULT_STORAGE_PATH = "storage/";
__gshared string DEFAULT_LOG_PATH = "logs/";
__gshared string DEFAULT_SESSION_PATH = "session/";
__gshared string DEFAULT_ATTACHMENT_PATH = "attachments/";

shared static this()
{
    APP_PATH = dirName(thisExePath());
    DEFAULT_CONFIG_PATH = buildPath(APP_PATH, DEFAULT_CONFIG_PATH);
    DEFAULT_TEMPLATE_PATH = buildPath(APP_PATH, DEFAULT_TEMPLATE_PATH);
    DEFAULT_LANGUAGE_PATH = buildPath(APP_PATH, DEFAULT_LANGUAGE_PATH);
    DEFAULT_PUBLIC_PATH = buildPath(APP_PATH, DEFAULT_PUBLIC_PATH);
    DEFAULT_STORAGE_PATH = buildPath(APP_PATH, DEFAULT_STORAGE_PATH);
    DEFAULT_LOG_PATH = buildPath(DEFAULT_STORAGE_PATH, DEFAULT_LOG_PATH);
    DEFAULT_SESSION_PATH = buildPath(DEFAULT_STORAGE_PATH, DEFAULT_SESSION_PATH);
    DEFAULT_ATTACHMENT_PATH = buildPath(APP_PATH, DEFAULT_ATTACHMENT_PATH);
}
