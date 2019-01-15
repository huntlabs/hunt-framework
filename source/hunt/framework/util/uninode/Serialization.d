/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.util.uninode.Serialization;

import std.stdio;

private
{
    import hunt.util.Serialize;
    import std.traits;
    import std.json;
    import hunt.framework.util.uninode.Core;
}

/**
 * Serialize object to UniNode
 *
 * Params:
 * object = serialized object
 */
UniNode serializeToUniNode(T)(T object)
{
    return _serializeToUniNode!T(object);
}

/**
 * Deserialize object form UniNode
 *
 * Params:
 * src = UniNode value
 */
T deserializeUniNode(T)(UniNode src)
{
    return _deserializeUniNode!T(src);
}

/**
 * Serialize object to UniNode
 *
 * Params:
 * object = serialized object
 */
UniNode jsonToUniNode(JSONValue object)
{
    return _jsonToUniNode(object);
}

/**
 * Deserialize object form UniNode
 *
 * Params:
 * src = UniNode value
 */
JSONValue uniNodeToJSON(UniNode src)
{
    return _uniNodeToJSON(src);
}


private
{
    /**
    * Serialize object to UniNode
    *
    * Params:
    * object = serialized object
    */
    UniNode _serializeToUniNode(T)(T object)
    {
        static if (is(T == UniNode))
        {
            return object;
        }
        else static if (isUniNodeType!(T, UniNode))
        {
            static if (isUniNodeInnerType!T)
            {
                return UniNode(object);
            }
            else static if (isUniNodeArray!(T, UniNode))
            {
                return UniNode(object);
            }
            else static if (isUniNodeObject!(T, UniNode))
            {
                return UniNode(object);
            }
        }
        else static if (is(T == struct) || is(T == class))
        {
            return _jsonToUniNode(toJSON(object));
        }
        else static if (isStaticArray!T)
        {
            UniNode[object.length] nodes;
            foreach (node; object)
            {
                nodes ~= _serializeToUniNode(node);
            }

            return UniNode(nodes);
        }
        else static if (isDynamicArray!T)
        {
            UniNode[] nodes;
            foreach (node; object)
            {
                nodes ~= _serializeToUniNode(node);
            }

            return UniNode(nodes);
        }
    }

    /**
    * Convert JSONValue to UniNode
    *
    * Params:
    * data = JSONValue
    */
    UniNode _jsonToUniNode(JSONValue data)
    {
        if (data.type == JSONType.INTEGER)
        {
            return UniNode(data.integer);
        }
        else if (data.type == JSONType.NULL)
        {
            return UniNode((null));
        }
        else if (data.type == JSONType.STRING)
        {
            return UniNode(data.str);
        }
        else if (data.type == JSONType.FALSE)
        {
            return UniNode(false);
        }
        else if (data.type == JSONType.TRUE)
        {
            return UniNode(true);
        }
        else if (data.type == JSONType.FLOAT)
        {
            return UniNode(data.floating);
        }
        else if (data.type == JSONType.UINTEGER)
        {
            return UniNode(data.uinteger);
        }
        else if (data.type == JSONType.ARRAY)
        {
            UniNode[] nodes;
            foreach (value; data.array)
            {
                nodes ~= _jsonToUniNode(value);
            }
            return UniNode(nodes);
        }
        else if (data.type == JSONType.OBJECT)
        {
            UniNode[string] node;
            foreach (k, v; data.object)
            {
                node[k] = _jsonToUniNode(v);
            }
            return UniNode(node);
        }
        return UniNode(null);
    }
    /**
    * Deserialize object form UniNode
    *
    * Params:
    * src = UniNode value
    */
    T _deserializeUniNode(T)(UniNode src)
    {
        static if (is(T == UniNode))
        {
            return src;
        }
        else static if (isUniNodeType!(T, UniNode))
        {
            return src.get!T();
        }
        else static if (is(T == struct) || is(T == class))
        {
            return toOBJ!T(_uniNodeToJSON(src));
        }
        else
        {
            return unserialize!(T)(cast(byte[])(src.get!(ubyte[])));
        }
    }
    /**
    * Convert UniNode to JSONValue
    *
    * Params:
    * data = UniNode
    */
    JSONValue _uniNodeToJSON(UniNode node)
    {
        JSONValue data;
        if (node.kind == UniNode.Kind.nil)
        {
            return data;
        }
        else if (node.kind == UniNode.Kind.boolean)
        {
            data = node.get!bool();
        }
        else if (node.kind == UniNode.Kind.uinteger)
        {
            data = node.get!ulong();
        }
        else if (node.kind == UniNode.Kind.integer)
        {
            data = node.get!long();
        }
        else if (node.kind == UniNode.Kind.floating)
        {
            data = node.get!real();
        }
        else if (node.kind == UniNode.Kind.text)
        {
            data = node.get!string();
        }
        else if (node.kind == UniNode.Kind.raw)
        {
            data = node.get!(ubyte[])();
        }
        else if (node.kind == UniNode.Kind.array)
        {
            JSONValue[] values;
            foreach (value; node)
            {
                values ~= _uniNodeToJSON(value);
            }
            data = values;
        }
        else if (node.kind == UniNode.Kind.object)
        {
            foreach (string k, UniNode v; node)
            {
                data[k] = _uniNodeToJSON(v);
            }
        }
        return data;
    }
}
