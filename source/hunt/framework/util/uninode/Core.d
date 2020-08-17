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

module hunt.framework.util.uninode.Core;

private
{
    import std.array : appender;
    import std.conv : to;
    import std.format : fmt = format;
    import std.traits;
    import std.traits : isTraitsArray = isArray;
    import std.variant : maxSize;
}


import hunt.logging.ConsoleLogger;

/**
 * UniNode implementation
 */
struct UniNodeImpl(This)
{
// @safe:
    private nothrow
    {
        alias Bytes = immutable(ubyte)[];

        union U
        {
            typeof(null) nil;
            bool boolean;
            ulong uinteger;
            long integer;
            real floating;
            string text;
            Bytes raw;
            This[] array;
            This[string] object;
        }

        struct SizeChecker
        {
            int function() fptr;
            ubyte[maxSize!U] data;
        }

        enum size = SizeChecker.sizeof - (int function()).sizeof;

        union
        {
            ubyte[size] _store;
            // conservatively mark the region as pointers
            static if (size >= (void*).sizeof)
                void*[size / (void*).sizeof] p;
        }

        Kind _kind;

        ref inout(T) getDataAs(T)() inout @trusted
        {
            static assert(T.sizeof <= _store.sizeof, "Size errro");
            return (cast(inout(T)[1])_store[0 .. T.sizeof])[0];
        }

        @property ref inout(This[string]) _object() inout
        {
            return getDataAs!(This[string])();
        }

        @property ref inout(This[]) _array() inout
        {
            return getDataAs!(This[])();
        }

        @property ref inout(bool) _bool() inout
        {
            return getDataAs!bool();
        }

        @property ref inout(long) _int() inout
        {
            return getDataAs!long();
        }

        @property ref inout(ulong) _uint() inout
        {
            return getDataAs!ulong();
        }

        @property ref inout(real) _float() inout
        {
            return getDataAs!real();
        }

        @property ref inout(string) _string() inout
        {
            return getDataAs!string();
        }

        @property ref inout(Bytes) _raw() inout
        {
            return getDataAs!(Bytes)();
        }
    }


    alias Kind = TypeEnum!U;


    Kind kind() @property inout nothrow pure
    {
        return _kind;
    }

    /**
     * Construct UniNode null value
     */
    this(typeof(null)) inout nothrow
    {
        _kind = Kind.nil;
    }

    /**
     * Check node is null
     */
    bool isNull() inout nothrow pure
    {
        return _kind == Kind.nil;
    }


    @safe unittest
    {
        auto node = immutable(UniNode)(null);
        assert (node.isNull);
        auto node2 = immutable(UniNode)();
        assert (node2.isNull);
    }

    /**
     * Construct UniNode from unsigned number value
     */
    this(T)(T val) inout nothrow if (isUnsignedNumeric!T)
    {
        _kind = Kind.uinteger;
        (cast(ulong)_uint) = val;
    }


    @safe unittest
    {
        import std.meta : AliasSeq;
        foreach (TT; AliasSeq!(ubyte, ushort, uint, ulong))
        {
            TT v = cast(TT)11U;
            auto node = immutable(UniNode)(v);
            assert (node.kind == UniNode.Kind.uinteger);
            assert (node.get!TT == cast(TT)11U);
        }
    }

    /**
     * Construct UniNode from signed number value
     */
    this(T)(T val) inout nothrow if (isSignedNumeric!T)
    {
        _kind = Kind.integer;
        (cast(long)_int) = val;
    }


    @safe unittest
    {
        import std.meta : AliasSeq;
        foreach (TT; AliasSeq!(byte, short, int, long))
        {
            TT v = -11;
            auto node = UniNode(v);
            assert (node.kind == UniNode.Kind.integer);
            assert (node.get!TT == cast(TT)-11);
        }
    }

    /**
     * Construct UniNode from boolean value
     */
    this(T)(T val) inout nothrow if (isBoolean!T)
    {
        _kind = Kind.boolean;
        (cast(bool)_bool) = val;
    }


    @safe unittest
    {
        auto node = UniNode(true);
        assert (node.kind == UniNode.Kind.boolean);
        assert (node.get!bool == true);

        auto nodei = UniNode(0);
        assert (nodei.kind == UniNode.Kind.integer);
    }

    /**
     * Construct UniNode from floating value
     */
    this(T)(T val) inout nothrow if (isFloatingPoint!T)
    {
        _kind = Kind.floating;
        (cast(real)_float) = val;
    }


    @safe unittest
    {
        import std.meta : AliasSeq;
        foreach (TT; AliasSeq!(float, double))
        {
            TT v = 11.11;
            auto node = UniNode(v);
            assert (node.kind == UniNode.Kind.floating);
            assert (node.get!TT == cast(TT)11.11);
        }
    }

    /**
     * Construct UniNode from string
     */
    this(string val) inout nothrow
    {
        _kind = Kind.text;
        (cast(string)_string) = val;
    }


    @safe unittest
    {
        string str = "hello";
        auto node = UniNode(str);
        assert(node.kind == UniNode.Kind.text);
        assert (node.get!(string) == "hello");
    }

    /**
     * Construct UniNode from byte array
     */
    this(T)(T val) inout nothrow if (isRawData!T)
    {
        _kind = Kind.raw;
        static if (isStaticArray!T || isMutable!T)
            (cast(Bytes)_raw) = val.idup;
        else
            (cast(Bytes)_raw) = val;
    }


    @safe unittest
    {
        ubyte[] dynArr = [1, 2, 3];
        auto node = UniNode(dynArr);
        assert (node.kind == UniNode.Kind.raw);
        assert (node.get!(ubyte[]) == [1, 2, 3]);

        ubyte[3] stArr = [1, 2, 3];
        node = UniNode(stArr);
        assert (node.kind == UniNode.Kind.raw);
        assert (node.get!(ubyte[3]) == [1, 2, 3]);

        Bytes bb = [1, 2, 3];
        node = UniNode(bb);
        assert (node.kind == UniNode.Kind.raw);
        assert (node.get!(ubyte[]) == [1, 2, 3]);
    }

    /**
     * Construct array UniNode
     */
    this(This[] val) nothrow
    {
        _kind = Kind.array;
        _array = val;
    }

    /**
     * Construct empty UniNode array
     */
    static This emptyArray() nothrow
    {
        return This(cast(This[])null);
    }

    /**
     * Check node is array
     */
    bool isArray() inout pure nothrow
    {
        return _kind == Kind.array;
    }


    @safe unittest
    {
        auto node = UniNode.emptyArray;
        assert(node.isArray);
        assert(node.length == 0);
    }

    /**
     * Construct object UnoNode
     */
    this(This[string] val) nothrow
    {
        _kind = Kind.object;
        _object = val;
    }

    /**
     * Construct empty UniNode object
     */
    static This emptyObject() nothrow
    {
        return This(cast(This[string])null);
    }

    /**
     * Check node is object
     */
    bool isObject() inout nothrow pure
    {
        return _kind == Kind.object;
    }


    @safe unittest
    {
        auto node = UniNode.emptyObject;
        assert(node.isObject);
    }


    size_t length() const @property
    {
        switch (_kind) with (Kind)
        {
            case text:
                return _string.length;
            case raw:
                return _raw.length;
            case array:
                return _array.length;
            case object:
                return _object.length;
            default:
                enforceUniNode(false, "Expected " ~ This.stringof ~ " not length");
                assert(false, "Nothing");
        }
    }


    alias opDollar = length;

    /**
     * Return value from UnoNode
     */
    inout(T) get(T)() inout @trusted if (isUniNodeType!(T, This))
    {
        static if (isSignedNumeric!T)
        {
            if (_kind == Kind.uinteger)
            {
                auto val = _uint;
                enforceUniNode(val < T.max, "Unsigned value great max");
                return cast(T)(val);
            }
            checkType!T(Kind.integer);
            return cast(T)(_int);
        }
        else static if (isUnsignedNumeric!T)
        {
            if (_kind == Kind.integer)
            {
                auto val = _int;
                enforceUniNode(val >= 0, "Signed value less zero");
                return cast(T)(val);
            }
            checkType!T(Kind.uinteger);
            return cast(T)(_uint);
        }
        else static if (isBoolean!T)
        {
            checkType!T(Kind.boolean);
            return _bool;
        }
        else static if (isFloatingPoint!T)
        {
            if (_kind == Kind.integer)
                return cast(T)(_int);
            if (_kind == Kind.uinteger)
                return cast(T)(_uint);

            checkType!T(Kind.floating);
            return cast(T)(_float);
        }
        else static if (isSomeString!T)
        {
            if (_kind == Kind.raw)
                return cast(T)_raw;
            checkType!T(Kind.text);
            return _string;
        }
        else static if (isRawData!T)
        {
            checkType!T(Kind.raw);
            static if (isStaticArray!T)
                return cast(inout(T))_raw[0..T.length];
            else
                return cast(inout(T))_raw;
        }
        else static if (isUniNodeArray!(T, This))
        {
            checkType!T(Kind.array);
            return _array;
        }
        else static if (isUniNodeObject!(T, This))
        {
            checkType!T(Kind.object);
            return _object;
        }
        else
            enforceUniNode(false, fmt!"Not support type '%s'"(T.stringof));
    }


    private int _opApply(F)(scope F dg)
    {
        auto fun = assumeSafe!F(dg);
        alias Params = Parameters!F;

        static if (Params.length == 1 && is(Unqual!(Params[0]) : This))
        {
            enforceUniNode(_kind == Kind.array,
                    "Expected " ~ This.stringof ~ " array");
            foreach (ref node; _array)
            {
                if (auto ret = fun(node))
                    return ret;
            }
        }
        else static if (Params.length == 2 && is(Unqual!(Params[1]) : This))
        {
            static if (isSomeString!(Params[0]))
            {
                enforceUniNode(_kind == Kind.object,
                        "Expected " ~ This.stringof ~ " object");
                foreach (string key, ref node; _object)
                {
                    if (auto ret = fun(key, node))
                        return ret;
                }
            }
            else
            {
                enforceUniNode(_kind == Kind.array,
                        "Expected " ~ This.stringof ~ " array");

                foreach (size_t key, ref node; _array)
                {
                    if (auto ret = fun(key, node))
                        return ret;
                }
            }
        }

        return 0;
    }

    /**
     * Iteration by UnoNode array or object
     */
    int opApply(scope int delegate(ref size_t idx, ref This node) dg)
    {
        return _opApply!(int delegate(ref size_t idx, ref This node))(dg);
    }

    /**
     * Iteration by UnoNode object
     */
    int opApply(scope int delegate(ref string idx, ref This node) dg)
    {
        return _opApply!(int delegate(ref string idx, ref This node))(dg);
    }

    /**
     * Iteration by UnoNode array
     */
    int opApply(scope int delegate(ref This node) dg)
    {
        return _opApply!(int delegate(ref This node))(dg);
    }


    size_t toHash() const nothrow @safe
    {
        final switch (_kind) with (Kind)
        {
            case nil:
                return 0;
            case boolean:
                return _bool.hashOf();
            case uinteger:
                return _uint.hashOf();
            case integer:
                return _int.hashOf();
            case floating:
                return _float.hashOf();
            case text:
                return _string.hashOf();
            case raw:
                return _raw.hashOf();
            case array:
                return _array.hashOf();
            case object:
                return _object.hashOf();
        }
    }


    @safe unittest
    {
        UniNode node;
        assert(node.toHash() == 0);

        node = UniNode(true);
        assert(node.toHash() == 1);
        node = UniNode(false);
        assert(node.toHash() == 0);
        node = UniNode(22u);
        assert(node.toHash() == 22);
        node = UniNode(-22);
        assert(node.toHash() == -22);
        node = UniNode(22.22);
        assert(node.toHash() == 3683678524);
        node = UniNode("1");
        assert(node.toHash() == 2484513939);
        ubyte[] data = [1, 2, 3];
        node = UniNode(data);
        assert(node.toHash() == 2161234436);
        node = UniNode([UniNode(1), UniNode(2)]);
        assert(node.toHash() == 9774061950961268414U);
        node = UniNode(["1": UniNode(1), "2": UniNode(2)]);
        assert(node.toHash() == 4159018407);

        auto node2 = UniNode(["2": UniNode(2), "1": UniNode(1)]);
        assert(node.toHash() == node2.toHash());
    }


    bool opEquals(const This other) const
    {
        return opEquals(other);
    }


    bool opEquals(ref const This other) const @trusted
    {
        version (HUNT_VIEW_DEBUG) {
            tracef("this: %s, other: %s", _kind, other.kind);
        }

        if (_kind != other.kind) {
            version(HUNT_DEBUG) {
                warningf("Different type for comparation, this: %s, other: %s", toString(), other.toString());
            }
            
            if(_kind == Kind.integer && other.kind == Kind.uinteger) {
                return _int == other._int;
            }
            if(_kind == Kind.uinteger && other.kind == Kind.integer) {
                return _uint == other._uint;
            }
            return false;
        }

        final switch (_kind) with (Kind)
        {
            case nil:
                return true;
            case boolean:
                return _bool == other._bool;
            case uinteger:
                return _uint == other._uint;
            case integer:
                return _int == other._int;
            case floating:
                return _float == other._float;
            case text:
                return _string == other._string;
            case raw:
                return _raw == other._raw;
            case array:
                return _array == other._array;
            case object:
                return _object == other._object;
        }
    }


    @safe unittest
    {
        auto n1 = UniNode(1);
        auto n2 = UniNode("1");
        auto n3 = UniNode(1);

        assert(n1 == n3);
        assert(n1 != n2);
        assert(n1 != UniNode(3));

        assert(UniNode([n1, n2, n3]) != UniNode([n2, n1, n3]));
        assert(UniNode([n1, n2, n3]) == UniNode([n1, n2, n3]));

        assert(UniNode(["one": n1, "two": n2]) == UniNode(["one": n1, "two": n2]));
    }

    /**
     * Implement operator in for object
     */
    inout(This)* opBinaryRight(string op)(string key) inout if (op == "in")
    {
        enforceUniNode(_kind == Kind.object, "Expected " ~ This.stringof ~ " object");
        return key in _object;
    }


    @safe unittest
    {
        auto node = UniNode(1);
        auto mnode = UniNode(["one": node, "two": node]);
        assert (mnode.isObject);
        assert("one" in mnode);
    }


    string toString() const
    {
        auto buff = appender!string;

        void fun(UniNodeImpl!This node) @safe const
        {
            switch (node.kind)
            {
                case Kind.nil:
                    buff.put("nil");
                    break;
                case Kind.boolean:
                    buff.put("bool("~node.get!bool.to!string~")");
                    break;
                case Kind.uinteger:
                    buff.put("uint("~node.get!ulong.to!string~")");
                    break;
                case Kind.integer:
                    buff.put("int("~node.get!long.to!string~")");
                    break;
                case Kind.floating:
                    buff.put("float("~node.get!double.to!string~")");
                    break;
                case Kind.text:
                    buff.put("text("~node.get!string.to!string~")");
                    break;
                case Kind.raw:
                    buff.put("raw("~node.get!(ubyte[]).to!string~")");
                    break;
                case Kind.object:
                {
                    buff.put("{");
                    immutable len = node.length;
                    size_t count;
                    foreach (ref string k, ref This v; node)
                    {
                        count++;
                        buff.put(k ~ ":");
                        fun(v);
                        if (count < len)
                            buff.put(", ");
                    }
                    buff.put("}");
                    break;
                }
                case Kind.array:
                {
                    buff.put("[");
                    immutable len = node.length;
                    size_t count;
                    foreach (size_t i, ref This v; node)
                    {
                        count++;
                        fun(v);
                        if (count < len)
                            buff.put(", ");
                    }
                    buff.put("]");
                    break;
                }
                default:
                    buff.put("undefined");
                    break;
            }
        }

        fun(this);
        return buff.data;
    }


    @safe unittest
    {
        auto obj = UniNode.emptyObject;

        auto intNode = UniNode(int.max);
        auto uintNode = UniNode(uint.max);
        auto fNode = UniNode(float.nan);
        auto textNode = UniNode("node");
        auto boolNode = UniNode(true);
        ubyte[] bytes = [1, 2, 3];
        auto binNode = UniNode(bytes);
        auto nilNode = UniNode();

        auto arrNode = UniNode([intNode, fNode, textNode, nilNode]);
        auto objNode = UniNode([
                "i": intNode,
                "ui": uintNode,
                "f": fNode,
                "text": textNode,
                "bool": boolNode,
                "bin": binNode,
                "nil": nilNode,
                "arr": arrNode]);

        assert(objNode.toString.length);
    }


    @safe unittest
    {
        auto node = UniNode();
        assert (node.isNull);

        auto anode = UniNode([node, node]);
        assert (anode.isArray);

        auto mnode = UniNode(["one": node, "two": node]);
        assert (mnode.isObject);
    }

    /**
     * Implement index operator by UniNode array
     */
    ref inout(This) opIndex(size_t idx) inout
    {
        enforceUniNode(_kind == Kind.array, "Expected " ~ This.stringof ~ " array");
        return _array[idx];
    }


    @safe unittest
    {
        auto arr = UniNode.emptyArray;
        foreach(i; 1..10)
            arr ~= UniNode(i);
        assert(arr[1] == UniNode(2));
    }

    /**
     * Implement index operator by UniNode object
     */
    ref inout(This) opIndex(string key) inout
    {
        enforceUniNode(_kind == Kind.object, "Expected " ~ This.stringof ~ " object");
        return _object[key];
    }


    @safe unittest
    {
        UniNode[string] obj;
        foreach(i; 1..10)
            obj[i.to!string] = UniNode(i*i);

        UniNode node = UniNode(obj);
        assert(node["2"] == UniNode(4));
    }

    /**
     * Implement index assign operator by UniNode object
     */
    ref This opIndexAssign(This val, string key)
    {
        return opIndexAssign(val, key);
    }

    /**
     * Implement index assign operator by UniNode object
     */
    ref This opIndexAssign(ref This val, string key)
    {
        enforceUniNode(_kind == Kind.object, "Expected " ~ This.stringof ~ " object");
        return _object[key] = val;
    }


    @safe unittest
    {
        UniNode node = UniNode.emptyObject;
        UniNode[string] obj;
        foreach(i; 1..10)
            node[i.to!string] = UniNode(i*i);

        assert(node["2"] == UniNode(4));
    }

    /**
     * Implement operator ~= by UniNode array
     */
    void opOpAssign(string op)(This[] elem) if (op == "~")
    {
        opOpAssign!op(UniNode(elem));
    }

    /**
     * Implement operator ~= by UniNode array
     */
    void opOpAssign(string op)(This elem) if (op == "~")
    {
        enforceUniNode(_kind == Kind.array, "Expected " ~ This.stringof ~ " array");
        _array ~= elem;
    }


    @safe unittest
    {
        auto node = UniNode(1);
        auto anode = UniNode([node, node]);
        assert(anode.length == 2);
        anode ~= node;
        anode ~= anode;
        assert(anode.length == 4);
        assert(anode[$-2] == node);
    }


private:


    void checkType(T)(Kind target, string file = __FILE__, size_t line = __LINE__) inout
    {
        enforceUniNode(_kind == target,
                fmt!("Trying to get %s but have %s.")(T.stringof, _kind),
                file, line);
    }
}

/**
 * Universal structure for data storage of different types
 */
struct UniNode
{
// @safe:
    UniNodeImpl!UniNode node;
    alias node this;


    this(V)(V val) inout
    {
        node = UniNodeImpl!UniNode(val);
    }

    size_t toHash() const nothrow @safe
    {
        return node.toHash();
    }

    bool opEquals(const UniNode other) const
    {
        return node.opEquals(other);
    }
}

/**
 * UniNode error class
 */
class UniNodeException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__,
            Throwable next = null) @safe pure
    {
        super(msg, file, line, next);
    }
}

/**
 * Enforce UniNodeException
 */
void enforceUniNode(T)(T value, lazy string msg = "UniNode exception",
        string file = __FILE__, size_t line = __LINE__) @safe pure
{
    if (!value)
        throw new UniNodeException(msg, file, line);
}

template isUniNodeType(T, This)
{
    enum isUniNodeType = isUniNodeInnerType!T
        || isUniNodeArray!(T, This) || isUniNodeObject!(T, This);
}

template isUniNodeInnerType(T)
{
    enum isUniNodeInnerType = isNumeric!T || isBoolean!T || isSomeString!T
        || is(T == typeof(null)) || isRawData!T;
}

private:

template TypeEnum(U)
{
    import std.array : join;
    enum msg = "enum TypeEnum : ubyte { " ~ [FieldNameTuple!U].join(", ") ~ " }";
    // pragma(msg, msg);
    mixin(msg);
}

/**
 * Check for an integer signed number
 */
template isSignedNumeric(T)
{
    enum isSignedNumeric = isNumeric!T && isSigned!T && !isFloatingPoint!T;
}

/**
 * Check for an integer unsigned number
 */
template isUnsignedNumeric(T)
{
    enum isUnsignedNumeric = isNumeric!T && isUnsigned!T && !isFloatingPoint!T;
}

/**
 * Checking for binary data
 */
template isRawData(T)
{
    enum isRawData = isTraitsArray!T && is(Unqual!(ForeachType!T) == ubyte);
}


template isUniNodeArray(T, This)
{
    enum isUniNodeArray = isTraitsArray!T && is(Unqual!(ForeachType!T) == This);
}

template isUniNodeObject(T, This)
{
    enum isUniNodeObject = isAssociativeArray!T
        && is(Unqual!(ForeachType!T) == This) && is(KeyType!T == string);
}

auto assumeSafe(F)(F fun) @safe
if (isFunctionPointer!F || isDelegate!F)
{
    static if (hasFunctionAttributes!(F, "@safe"))
        return fun;
    else
        return (ParameterTypeTuple!F args) @trusted
        {
            return fun(args);
        };
}
