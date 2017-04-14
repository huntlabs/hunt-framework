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
 
module hunt.cache.base;

import std.conv;

abstract class Cache
{
	///set cache key prefix
	void setPrefix(string prefix)
	{
		_prefix = prefix;
	}

	///fetch a cache value by key, if empty value return default value v
	final T get(T = string)(string key, lazy T v= T.init)
	{
		 auto tmp = getByKey(_prefix,key,v);
		if(tmp == string.init)
		{
			return v;
		}
		return to!T(tmp);
	}

	 string getByKey(string master_key,string key, lazy string v= string.init);
	
	///add a cache  expired after expires seconeds
	final bool set(string key, string value, int expires = 0)
	{
		return setByKey(_prefix,key,value,expires);
	}

	bool setByKey(string master_key,string key, string value, int expires);

	///remove a cache by cache key
	final bool remove(string key)
	{
		return removeByKey(_prefix,key);
	}

	bool removeByKey(string master_key,string key);

protected:
	string _prefix;
}
