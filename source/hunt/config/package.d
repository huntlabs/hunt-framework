module hunt.config;

shared string huntConfigPath = "";

public import hunt.config.config;
public import hunt.config.exception;
public import hunt.config.ini;
public import hunt.config.json;
public import hunt.config.xml;
public import hunt.config.yaml;

shared static this()
{
    import core.runtime;

    auto list = Runtime.args();
    if (list.length > 1)
    {
        huntConfigPath = list[1];
    }
    else
    {
        import std.path;

        huntConfigPath = absolutePath(dirName(list[0]));
    }
}
