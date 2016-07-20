module hunt.view.templerender;

public import hunt.view;

class View
{
private:
	TempleContext _context;
	CompiledTemple _layout;

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
		if(_layout.toString)
		{
			auto composed = _layout.layout(&child);
			return composed.toString(context);
		}
		else
		{
			return child.toString(context);
		}
	}
}
