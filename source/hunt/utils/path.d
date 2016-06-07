 
module hunt.utils.path;

public import std.path;

//TODO: if in the bin path, the path will be start path
@property theExecutorPath()
{
    return _theExecutorPath;
}

private:

shared string _theExecutorPath = "";

shared static this()
{
    import core.runtime;

    auto list = Runtime.args();
    _theExecutorPath = absolutePath(dirName(list[0]));
}
