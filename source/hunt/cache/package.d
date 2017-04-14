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
