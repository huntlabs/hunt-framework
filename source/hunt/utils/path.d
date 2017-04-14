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
 
module hunt.utils.path;

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
	import std.path;
	import std.file;
	
	auto list = Runtime.args();
	_theExecutorPath = absolutePath(thisExePath);
	if(list.length == 1)
	{
		_theConfigPath = _theExecutorPath;
	}
	else
	{
		_theConfigPath = absolutePath(list[1]);
	}
}
