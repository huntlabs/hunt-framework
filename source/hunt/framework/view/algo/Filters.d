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

module hunt.framework.view.algo.Filters;

private
{
    import hunt.framework.view.algo.Wrapper;
    import hunt.framework.view.Uninode;
}

// dfmt off
Function[string] globalFilters()
{
    return cast(immutable)
        [
            "default": wrapper!defaultVal,
            "d":       wrapper!defaultVal,
            "escape":  wrapper!escape,
            "e":       wrapper!escape,
            "upper":   wrapper!upper,
            "lower":   wrapper!lower, 
            "sort":    wrapper!sort,
            "keys":    wrapper!keys,
        ];
}
// dfmt on

UniNode defaultVal(UniNode value, UniNode default_value = UniNode(""), bool boolean = false)
{
    if (value.kind == UniNode.Kind.nil)
        return default_value;

    if (!boolean)
        return value;

    value.toBoolType;
    if (!value.get!bool)
        return default_value;

    return value;
}


string escape(string s)
{
    import std.array : appender;

    auto w = appender!string;
    w.reserve(s.length);

    foreach (char ch; s)
        switch (ch)
        {
            case '&':  w.put("&amp;");  break;
            case '\"': w.put("&quot;"); break;
            case '\'': w.put("&apos;"); break;
            case '<':  w.put("&lt;");   break;
            case '>':  w.put("&gt;");   break;
            default:   w.put(ch);       break;
        }

    return w.data;
}


string upper(string str)
{
    import std.uni : toUpper;
    return str.toUpper;
}

string lower(string str)
{
    import std.uni : toLower;
    return str.toLower;
}

UniNode sort(UniNode value)
{
    import std.algorithm : sort;

    switch (value.kind) with (UniNode.Kind)
    {
        case array:
            auto arr = value.get!(UniNode[]);
            sort!((a, b) => a.getAsString < b.getAsString)(arr);
            return UniNode(arr);

        case object:
            UniNode[] arr;
            foreach (string key, val; value)
                arr ~= UniNode([UniNode(key), val]);
            sort!"a[0].get!string < b[0].get!string"(arr);
            return UniNode(arr);

        default:
            return value;
    }
}


UniNode keys(UniNode value)
{
    if (value.kind != UniNode.Kind.object)
        return UniNode(null);

    UniNode[] arr;
    foreach (string key, val; value)
        arr ~= UniNode(key);
    return UniNode(arr);
}
