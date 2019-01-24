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

module hunt.framework.util.Formatter;

private
{
    import std.regex;
    import std.json;
    import std.array;
    import std.string;
    import std.format;
}

private
{
    const string formatSpecifier = "%(\\d+\\$)?([-#+ 0,(\\<]*)?(\\d+)?(\\.\\d+)?([tT])?([a-zA-Z%])";

    string[] parseFormat(string message)
    {
        string[] frams;
        int offset = 0;
        auto matchers = matchAll(message, regex(formatSpecifier, "im"));
        foreach (matcher; matchers)
        {
            string text = matcher.captures[0];
            int pos = cast(int)(message[offset .. $].indexOf(text)) + offset;
            frams ~= message[offset .. pos + text.length];
            offset = pos + cast(int)(text.length);
        }
        if (offset != message.length)
            frams ~= message[offset .. $];
        return frams;
    }
}

string StrFormat(string message, JSONValue data)
{
    void singleFormat(ref Appender!string buffer, string text, JSONValue item)
    {
        switch (item.type) with (JSONType)
        {
        case INTEGER:
            formattedWrite(buffer, text, item.integer);
            break;
        case UINTEGER:
            formattedWrite(buffer, text, item.uinteger);
            break;
        case FLOAT:
            formattedWrite(buffer, text, item.floating);
            break;
        case STRING:
            formattedWrite(buffer, text, item.str);
            break;
        case TRUE:
            formattedWrite(buffer, text, true);
            break;
        case FALSE:
            formattedWrite(buffer, text, false);
            break;
        default:
            throw new Exception("error param : " ~ item.toString);
        }
    }

    auto frams = parseFormat(message);
    if (data.type == JSONType.array)
    {
        assert(frams.length >= data.array.length);
        Appender!string buffer;
        for (int i = 0; i < data.array.length; i++)
        {
            JSONValue item = data.array[i];
            singleFormat(buffer, frams[i], item);
        }
        for (size_t i = data.array.length; i < frams.length; i++)
            buffer.put(frams[i]);
        return buffer.data;
    }
    else
    {
        Appender!string buffer;
        singleFormat(buffer, frams[0], data);
        for (size_t i = 1; i < frams.length; i++)
            buffer.put(frams[i]);
        return buffer.data;
    }
}

string StrFormat(A...)(string message , lazy A args)
{
    Appender!string buffer;
    formattedWrite(buffer, message, args);
    return buffer.data;
}

unittest
{
    import std.json;
    import std.stdio;

    string message = "hello %s, your id is %2d, 
                                        your score is %.2f, byte!";
	JSONValue data = [JSONValue("gaoxincheng"),JSONValue(100),JSONValue(89.345)];

	writeln("format message : ",StrFormat(message,data));

	string msg1 = "hello %s ! ";
	writeln("format msg1 : ",StrFormat(msg1,JSONValue(" world")));

	string msg2 = "hello world! ";
	writeln("format msg2 : ",StrFormat(msg2,JSONValue(1)));

	writeln("format varags : ",StrFormat(message,"gaoxincheng",99,45.2223));

	// UniNode nodes = [UniNode("world"),UniNode(100),UniNode(89.345)];

	// writeln("format message by UniNode : ",StrFormat(message,uniNodeToJSON(nodes)));
}