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
module hunt.view;

public import hunt.view.util, hunt.view.delims, hunt.view.funcstringgen;
public import std.array : appender, Appender;
public import std.range : isOutputRange;
public import std.typecons : scoped;
public import std.stdio;
public import std.regex;
public import std.file;

public
{
    import hunt.view.templecontext : TempleContext;
    import hunt.view.outputstream : TempleOutputStream, TempleInputStream;
}

/**
 * Temple
 * Main template for generating Temple functions
 */
CompiledTemple compile_temple(string __TempleString, __Filter = void,
    uint line = __LINE__, string file = __FILE__)()
{
    import std.conv : to;

    return compile_temple!(__TempleString, file ~ ":" ~ line.to!string ~ ": InlineTemplate",
        __Filter);
}

deprecated("Please use compile_temple") auto Temple(ARGS...)()
{
    return .compile_temple!(ARGS)();
}

public CompiledTemple compile_temple(string __TempleString, string __TempleName, __Filter = void)()
{
	//writeln("__TempleString:",template_parsing(__TempleString));
	//writeln("__TempleName:",__TempleName);
    // __TempleString: The template string to compile
    // __TempleName: The template's file name, or 'InlineTemplate'
    // __Filter: FP for the rendered template

    // Is a Filter present?
    enum __TempleHasFP = !is(__Filter == void);

    // Needs to be kept in sync with the param name of the Filter
    // passed to Temple
    enum __TempleFilterIdent = __TempleHasFP ? "__Filter" : "";

    // Generates the actual function string, with the function name being
    // `TempleFunc`.
    //const string str = template_parsing!__TempleString;
    const __TempleFuncStr = __temple_gen_temple_func_string(__TempleString,
        __TempleName, __TempleFilterIdent);

    //pragma(msg, __TempleFuncStr);

    mixin(__TempleFuncStr);
    //pragma(msg, "TempleFunc ", __TempleFuncStr, "...");

    static if (__TempleHasFP)
    {
        alias temple_func = TempleFunc!__Filter;
    }
    else
    {
        alias temple_func = TempleFunc;
    }

    return CompiledTemple(&temple_func, null);
}

/**
 * TempleFile
 * Compiles a file on the disk into a Temple render function
 * Takes an optional Filter
 */
CompiledTemple compile_temple_file(string template_file, Filter = void)()
{
    pragma(msg, "Compiling ", template_file, "...");
    return compile_temple!(import(template_file), template_file, Filter);
}

CompiledTemple display(string template_file)()
{
    auto template_string = import(template_file);
    auto template_string_parsing = template_parsing(template_string);
    return compile_temple!template_string_parsing;
}


string template_parsing(string template_string)
{
    auto re = regex(r"\{!.*!\}","mg");
    auto temple_match = matchFirst(template_string,re);
    if(!temple_match)
    {
        return template_string;
    }
    else
    {
        writeln(temple_match);
        auto template_file = temple_match[0][2 .. $ - 2];
        auto template_file_string = readText("../hunt/resources/views/"~template_file);
        const string new_template_string = replaceFirst(template_string,re,template_file_string);
        //const string new_template_string = template_string.replace(temple_match[0], template_file_string);
        if(!matchAll(new_template_string,re))
        {
            return new_template_string;
        }
        else
        {
            return template_parsing(new_template_string);
        }
    }
}

deprecated("Please use compile_temple_file") auto TempleFile(ARGS...)()
{
    return .compile_temple_file!(ARGS)();
}

/**
 * TempleFilter
 * Curries a Temple to always use a given template filter, for convienence
 */
template TempleFilter(Filter)
{
    template compile_temple(ARGS...)
    {
        alias compile_temple = .compile_temple!(ARGS, Filter);
    }

    template compile_temple_file(ARGS...)
    {
        alias compile_temple_file = .compile_temple_file!(ARGS, Filter);
    }

    deprecated("Please compile_temple") alias Temple = compile_temple;
    deprecated("Please compile_temple_file") alias TempleFile = compile_temple_file;
}

/**
 * CompiledTemple
 */
package struct CompiledTemple
{

package:
    alias TempleFuncSig = void function(TempleContext);
    TempleFuncSig render_func = null;

    // renderer used to handle 'yield's
    const(CompiledTemple)* partial_rendr = null;

    this(TempleFuncSig rf, const(CompiledTemple*) cf)
    in
    {
        assert(rf);
    }
    body
    {
        this.render_func = rf;
        this.partial_rendr = cf;
    }

public:
    //deprecated static Temple opCall()

    // render template directly to a string
    string toString(TempleContext tc = null) const
    {
        auto a = appender!string();
        this.render(a, tc);
        return a.data;
    }

    // render using an arbitrary output range
    void render(T)(ref T os, TempleContext tc = null) const
    {
        if (isOutputRange!(T, string) && !is(T == TempleOutputStream))
        {
            auto oc = TempleOutputStream(os);
            return render(oc, tc);
        }
    }

    // render using a sink function (DMD can't seem to cast a function to a delegate)
    void render(void delegate(string) sink, TempleContext tc = null) const
    {
        auto oc = TempleOutputStream(sink);
        this.render(oc, tc);
    }

    void render(void function(string) sink, TempleContext tc = null) const
    {
        auto oc = TempleOutputStream(sink);
        this.render(oc, tc);
    }

    import std.stdio;

    void render(ref std.stdio.File f, TempleContext tc = null) const
    {
        auto oc = TempleOutputStream(f);
        this.render(oc, tc);
    }

    // normalized render function, using an TempleOutputStream
    package void render(ref TempleOutputStream os, TempleContext tc) const
    {
        // the context never escapes the scope of a template, so it's safe
        // to allocate a new context here
        // TODO: verify this is safe
        auto local_tc = scoped!TempleContext();

        // and always ensure that a template is passed, at the very least,
        // an empty context (needed for various template scope book keeping)
        if (tc is null)
        {
            tc = local_tc.Scoped_payload;
            //tc = new TempleContext();
        }

        // template renders into given output stream
        auto old = tc.sink;
        scope (exit)
            tc.sink = old;
        tc.sink = os;

        // use the layout if we've got one
        if (this.partial_rendr !is null)
        {
            auto old_partial = tc.partial;

            tc.partial = this.partial_rendr;
            scope (exit)
                tc.partial = old_partial;

            this.render_func(tc);
        }
        // else, call this render function directly
        else
        {
            this.render_func(tc);
        }
    }

    CompiledTemple layout(const(CompiledTemple*) partial) const
    in
    {
        assert(this.partial_rendr is null, "attempting to set already-set partial of a layout");
    }
    body
    {
        //writeln("\n into layout function : ",this.render_func, "-", partial);
        return CompiledTemple(this.render_func, partial);
    }

    invariant()
    {
        assert(render_func);
    }
}
