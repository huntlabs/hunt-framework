module hunt.view.context;

import std.variant;
import std.array;
import std.string;
import std.typetuple;

import hunt.view;

alias TempleContext = ViewContext;
class ViewContext
{
	public Variant[string] vars;

	void opIndexAssign(T)(string name, T val)
	{
		if (name !in vars)
			vars[name] = Variant();
		vars[name] = val;
	}
	void opDispatch(string name, T)(T val)
	{
		if (name !in vars)
			vars[name] = Variant();
		vars[name] = val;
	}
	Variant opDispatch(string name)()
	{
		if(name in vars)
			return Variant(vars[name]);
		return Variant.init;
	}
}
