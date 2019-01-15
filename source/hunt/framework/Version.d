/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.Version;

import std.conv : to;

// define hunt framework versions
enum int HUNT_MAJOR_VERSION = 2;
enum int HUNT_MINOR_VERSION = 0;
enum int HUNT_PATCH_VERSION = 0;

enum HUNT_VERSION = HUNT_MAJOR_VERSION.to!string ~ "." ~ to!string(HUNT_MINOR_VERSION) ~ "." ~ to!string(HUNT_PATCH_VERSION);
enum XPoweredBy = "Hunt framework v" ~ HUNT_VERSION;
