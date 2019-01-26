module hunt.framework.file.Exceptions;

import std.format;

class FileException : Exception
{
    this(string message, string file = __FILE__, size_t line = __LINE__)
    {
        super(message, file, line);
    }
}

class AccessDeniedException : Exception
{
    this(string path, string file = __FILE__, size_t line = __LINE__)
    {
        super(format("The file %s could not be accessed.", path), file, line);
    }
}

class FileNotFoundException : Exception
{
    this(string path, string file = __FILE__, size_t line = __LINE__)
    {
        super(format("The file %s does not exist.", path), file, line);
    }
}
