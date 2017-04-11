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
module hunt.cache;

public import hunt.cache.base;
public import hunt.cache.mapcache;

@property defaultCache()
{
	if(_cache is null)
	{
		_cache = MapCache.defaultCahe();
	}
	return _cache;
}

private:
Cache _cache;
