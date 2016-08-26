 
module hunt.utils.path;

public import std.path;

//TODO: if in the bin path, the path will be start path
//TODO: if in the bin path, the path will be start path
@property theExecutorPath()
{
	return _theExecutorPath;
}

@property theConfigPath()
{
	return _theConfigPath;
}

private shared string _theExecutorPath = "";
private shared string _theConfigPath = "";

shared static this()
{
	import core.runtime;
	
	auto list = Runtime.args();
	_theExecutorPath = absolutePath(dirName(list[0]));
	if(list.length == 1)
	{
		_theConfigPath = _theExecutorPath;
	}
	else
	{
		_theConfigPath = absolutePath(list[1]);
	}
}
