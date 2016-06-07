/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */
module hunt.text.exception;

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
