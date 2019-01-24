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
    import hunt.framework.view.Exception : assertTemplate = assertTemplateException;
    import hunt.framework.view.Uninode;

    import std.functional : toDelegate;
    import std.format : fmt = format;
}


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
            "trans":toDelegate(&trans)
        ];
}


UniNode range(UniNode params)
{
    import std.range : iota;
    import std.array : array;
    import std.algorithm : map;

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
string date(string format , long timestamp)
{
    return null;
}
///dummy
string url(string format , string d)
{
    return null;
}