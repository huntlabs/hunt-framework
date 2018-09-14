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

module hunt.framework.versions;

import std.conv;

// define hunt framework versions
enum int HUNT_MAJOR_VERSION = 2;
enum int HUNT_MINOR_VERSION = 0;
enum int HUNT_PATCH_VERSION = 0;

enum HUNT_VERSION = HUNT_MAJOR_VERSION.to!string ~ "." ~ to!string(HUNT_MINOR_VERSION) ~ "." ~ to!string(HUNT_PATCH_VERSION);
enum XPoweredBy = "Hunt framework v" ~ HUNT_VERSION;
