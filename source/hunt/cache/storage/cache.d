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
module hunt.cache.storage.cache;

interface CacheStorageInterface
{
	///set cache key prefix
	void setPrefix(string prefix);

	///fetch a cache value by key, if empty value return default value v
	T get(T = string)(string key, lazy T v = T.init);

	///add a cache  expired after expires seconeds
	bool set(string key, string value, int expires);

	///remove a cache by cache key
	bool remove(string key);
}