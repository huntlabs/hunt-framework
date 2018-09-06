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

module hunt.framework.routing.config;

import hunt.framework.routing.define;

struct RouteItem
{
    string methods;
    string path;
    string route;
}

struct RouteConfig
{
    RouteItem[] loadConfig(string filename)
    {
        import std.stdio;

        RouteItem[] items;

        auto f = File(filename);

        scope(exit)
        {
            f.close();
        }

        foreach (line; f.byLine)
        {
            RouteItem item = this.parseOne(line);
            if (item.path.length > 0)
            {
                items ~= item;
            }
        }

        return items;
    }

    RouteItem parseOne(char[] line)
    {
        import std.string : strip;
        import std.regex;
        import std.conv;

        RouteItem item;

        line = strip(line);

        // not availabale line return null
        if (line.length == 0 || line[0] == '#')
        {
            return item;
        }

        // match example: GET, POST    /users    module.controller.action | staticDir:public
        auto matched = line.match(regex(`([^/]+)\s+(/[\S]*?)\s+((staticDir[\:][\w|\/|\\]+)|([\w\.]+))`));

        if (matched)
        {
            item.methods = matched.captures[1].to!string.strip;
            item.path = matched.captures[2].to!string.strip;
            item.route = matched.captures[3].to!string.strip;
        }

        return item;
    }
}
