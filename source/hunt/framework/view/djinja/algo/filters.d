/**
  * Description of global filters
  *
  * Copyright:
  *     Copyright (c) 2018, Maxim Tyapkin.
  * Authors:
  *     Maxim Tyapkin
  * License:
  *     This software is licensed under the terms of the BSD 3-clause license.
  *     The full terms of the license can be found in the LICENSE.md file.
  */

module hunt.framework.view.djinja.algo.filters;

private
{
    import hunt.framework.view.djinja.algo.wrapper;
    import hunt.framework.view.djinja.uninode;
}


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
