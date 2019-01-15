/**
  * Description of global functions
  *
  * Copyright:
  *     Copyright (c) 2018, Maxim Tyapkin.
  * Authors:
  *     Maxim Tyapkin
  * License:
  *     This software is licensed under the terms of the BSD 3-clause license.
  *     The full terms of the license can be found in the LICENSE.md file.
  */

module hunt.framework.view.djinja.algo.functions;

private
{
    import hunt.framework.view.djinja.algo.wrapper;
    import hunt.framework.view.djinja.exception : assertJinja = assertJinjaException;
    import hunt.framework.view.djinja.uninode;

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
            "lang": wrapper!lang,
            "date": wrapper!date
        ];
}


UniNode range(UniNode params)
{
    import std.range : iota;
    import std.array : array;
    import std.algorithm : map;

    assertJinja(params.kind == UniNode.Kind.object, "Non object params");
    assertJinja(cast(bool)("varargs" in params), "Missing varargs in params");

    if (params["varargs"].length > 0)
    {
        auto length = params["varargs"][0].get!long;
        auto arr = iota(length).map!(a => UniNode(a)).array;
        return UniNode(arr);
    }

    assertJinja(0);
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
            assertJinja(0, "Object of type `%s` has no length()".fmt(value.kind));
    }
    assert(0);
}


UniNode namespace(UniNode kwargs)
{
    return kwargs;
}

///fake
string lang(string la)
{   
     return la;
}
///fake
string date(string format , long timestamp)
{
    return null;     
}