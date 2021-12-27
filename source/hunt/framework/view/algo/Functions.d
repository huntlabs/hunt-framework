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

module hunt.framework.view.algo.Functions;

private
{
    import hunt.framework.view.algo.Wrapper;
    import hunt.framework.view.Exception : assertTemplate = assertTemplateException, TemplateRenderException;
    import hunt.framework.view.Uninode;

    import hunt.logging;

    import std.array : array;
    import std.algorithm : map;   
    import std.functional : toDelegate;
    import std.format : fmt = format;
    import std.conv;

    import std.range : iota;
    import std.string; 
}

// dfmt off
Function[string] globalFunctions()
{
    return cast(immutable)
        [
            "range": toDelegate(&range),
            "length": wrapper!length,
            "count": wrapper!length,
            "namespace": wrapper!namespace,
            "date": wrapper!date,
            "url": wrapper!url,
            "int": wrapper!Int,
            "split": wrapper!split,
            "string": wrapper!String,
            "trans":toDelegate(&trans),
            "format" : toDelegate(&doFormat)
        ];
}
// dfmt on

/**
 * "a, b, c"  => ["a", "b", "c"]
 */
UniNode split(UniNode str, UniNode seperator = UniNode(",") ) { 
    version(HUNT_VIEW_DEBUG) {
        tracef("params: %s,  kind: %s", str.toString(), str.kind());
        tracef("seperator: %s,  kind: %s", seperator.toString(), seperator.kind());
    }

    if(str.kind() != UniNode.Kind.text && seperator.kind() != UniNode.Kind.text) {
        assertTemplate(0, "Only string supported");
        return UniNode("");
    }

    string separator = seperator.get!string();
    string value = str.get!string;
    string[] items = std.string.split(value, separator);
    UniNode[] arr = items.map!(a => UniNode(a.strip())).array;

    return UniNode(arr);
}


UniNode range(UniNode params)
{

    assertTemplate(params.kind == UniNode.Kind.object, "Non object params");
    assertTemplate(cast(bool)("varargs" in params), "Missing varargs in params");

    if (params["varargs"].length > 0)
    {
        auto length = params["varargs"][0].get!long;
        auto arr = iota(length).map!(a => UniNode(a)).array;
        return UniNode(arr);
    }

    assertTemplate(0);
    assert(0);
}

long length(UniNode value)
{
    switch (value.kind) with (UniNode.Kind)
    {
    case array:
    case object:
        return value.length;
    case text:
        return value.get!string.length;
    default:
        assertTemplate(0, "Object of type `%s` has no length()".fmt(value.kind));
    }
    assert(0);
}

int Int(UniNode value)
{
    switch (value.kind) with (UniNode.Kind)
    {
    case integer:
        return cast(int)(value.get!long);
    case uinteger:
        return cast(int)(value.get!ulong);
    case boolean:
        return value.get!bool ? 1 : 0;
    case text:
        return value.get!string
            .to!int;
    default:
        assertTemplate(0, "Object of type `%s` has no int()".fmt(value.kind));
    }
    assert(0);
}

string String(UniNode value)
{
    switch (value.kind) with (UniNode.Kind)
    {
    case integer:
        return to!string(value.get!long);
    case uinteger:
        return to!string(value.get!ulong);
    case boolean:
        return value.get!bool ? "true" : "false";
    case text:
        return value.get!string;
    default:
        assertTemplate(0, "Object of type `%s` has no string()".fmt(value.kind));
    }
    assert(0);
}

UniNode namespace(UniNode kwargs)
{
    return kwargs;
}

///dummy
UniNode trans(UniNode node)
{
    return UniNode(null);
}

///dummy
string date(string format, long timestamp)
{
    return null;
}
///dummy
string url(string format, string d)
{
    return null;
}

UniNode doFormat(UniNode args)
{
    import hunt.framework.util.Formatter;
    import hunt.framework.util.uninode.Serialization;

    if ("varargs" in args)
    {
        args = args["varargs"];
    }

    if (args.kind == UniNode.Kind.array)
    {
        if (args.length == 1)
        {
            return args[0];
        }
        else if (args.length > 1)
        {
            string msg = args[0].get!string;
            UniNode[] params;
            for (int i = 1; i < args.length; i++)
            {
                params ~= args[i];
            }

            return UniNode(StrFormat(msg, uniNodeToJSON(UniNode(params))));
        }
    }
    throw new TemplateRenderException("unsupport param : " ~ args.toString);
}
