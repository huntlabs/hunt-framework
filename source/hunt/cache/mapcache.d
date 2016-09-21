module hunt.cache.mapcache;

import hunt.cache.base;
import std.experimental.logger;
import std.string;
import core.sync.rwmutex;

class MapCache : Cache
{
	static @property defaultCahe()
	{
		if(_storage is null)
		{
			_storage = new MapCache();
		}
		return _storage;
	}

	this()
	{
		_mutex = new ReadWriteMutex();
	}

	~this(){_mutex.destroy;}

	override string getByKey(string master_key,string key, lazy string v= string.init)
	{
		string pk = master_key ~ key;
		_mutex.reader.lock();
		scope(exit) _mutex.reader.unlock();
		return _map.get(pk,v);
	}
	///add a cache  expired after expires seconeds
	/// NOTES : expires is not used
	override bool setByKey(string master_key,string key, string value, int expires)
	{
		string pk = master_key ~ key;
		_mutex.writer.lock();
		scope(exit) _mutex.writer.unlock();
		_map[pk] = value;
		return true;
	}
	
	///remove a cache by cache key
	override bool removeByKey(string master_key,string key)
	{
		string pk = master_key ~ key;
		_mutex.writer.lock();
		scope(exit) _mutex.writer.unlock();
		_map.remove(pk);
		return true;
	}


private:
	static MapCache _storage;

	string[string] _map;
	ReadWriteMutex _mutex;
}

