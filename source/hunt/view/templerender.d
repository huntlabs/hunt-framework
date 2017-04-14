/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.view.templerender;

public import hunt.view;

class View
{
private:
	TempleContext _context;
	CompiledTemple _layout;
	bool _setLayout = false;

public:

	TempleContext context()
	{
		if(_context is null)
		{
			_context = new TempleContext();
		}
		return _context;
	}

	void setLayout(string filename = null)()
	{
		_setLayout = true;
		_layout = compile_temple_file!filename;
	}

	void opIndexAssign(T)(string name, T val)
	{
		context[name] = val;
	}

	void opDispatch(string name, T)(T val)
	{
		context[val] = name;
	}

	string render(string filename = null)()
	{
		auto child = compile_temple_file!filename; 
		if(_setLayout)
		{
			_setLayout = false;
			auto composed = _layout.layout(&child);
			return composed.toString(context);
		}
		else
		{
			return child.toString(context);
		}
	}

	string show(string filename = null)()
	{
		auto child = compile_temple_file!filename; 
		return child.toString(context);
	}
}
