module hunt.view.render;

import std.stdio;
import std.conv;

import hunt.view;

alias display = compile_temple;
alias display = compile_temple_file;

CompiledTemple compile_temple_file(string template_file, Filter = void)()
{
	pragma(msg, "Compiling ", template_file, "...");
	return compile_temple!(import(template_file), template_file, Filter);
}

CompiledTemple compile_temple(string __TempleString, string __TempleName, __Filter = void)()
{
	//pragma(msg, "Compiling ",__TempleString);
	const __tsf = (new Parser(__TempleString)).toString; 
	//pragma(msg, "__tsf ",__tsf);
	mixin(__tsf);
	alias temp_func = TempleFunc;
	return CompiledTemple(&temp_func);
}

struct CompiledTemple
{
	alias rend_func = string function(ViewContext,CompiledTemple* ct) @system;
	public rend_func rf = null;
	public CompiledTemple* ct = null;
	this(rend_func rf)
	{
		this.rf = rf;
	}
	this(rend_func rf , CompiledTemple* ct)
	{
		this.rf = rf;
		this.ct = ct;
	}
	string toString(ViewContext ctx)
	{
		return this.rf(ctx,this.ct);
	}
	CompiledTemple layout(CompiledTemple* ct)
	{
		return CompiledTemple(rf,ct);
	}
}
