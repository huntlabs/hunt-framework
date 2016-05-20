/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 * template parsing is based on dymk/temple source from https://github.com/dymk/temple 
 */
module hunt.web.view.output_stream;

private
{
    import std.range;
    import std.stdio;
}

// Wraps any generic output stream/sink
struct TempleOutputStream
{
private:
    //void delegate(string) scope_sink;
    void delegate(string) sink;

public:
    this(T)(ref T os) if (isOutputRange!(T, string))
    {
        this.sink = delegate(str) { os.put(str); };
    }

    this(ref File f)
    {
        this.sink = delegate(str) { f.write(str); };
    }

    this(void delegate(string) s)
    {
        this.sink = s;
    }

    this(void function(string) s)
    {
        this.sink = delegate(str) { s(str); };
    }

    void put(string s)
    {
        this.sink(s);
    }

    // for vibe.d's html escape
    // TODO: write own html escaping mechanism, as this one requires an allocation
    // made for each char written to the output
    void put(dchar d)
    {
        import std.conv;

        this.sink(d.to!string);
    }

    invariant()
    {
        assert(this.sink !is null);
    }
}

// newtype struct
struct TempleInputStream
{
    // when called, 'into' pipes its output into OutputStream
    void delegate(ref TempleOutputStream os) into;

    invariant()
    {
        assert(this.into !is null);
    }
}
