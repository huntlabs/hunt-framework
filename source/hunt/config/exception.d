module hunt.config.exception;

/**
* Exception thrown during config parser errors
*/
class HuntConfigException : Exception
{
    /**
	* Constructor
	*
	* Params:
	*      msg = The message
	*      file = The file
	*      line = The line
	*/

    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}
