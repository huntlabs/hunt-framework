module hunt.storage.driver.file;

import hunt.utils.time;
import std.stdio;
import core.memory;
import stdFile = std.file;
import stdPath = std.path;
import core.sync.rwmutex;

__gshared FileStorage _file;
@property FileInstance()
{
	if(_file is null)
	{
		_file = new FileStorage;
	}
	return  _file;
}
class FileStorage
{
	private ReadWriteMutex _mutex;

	this()
	{
		_mutex = new ReadWriteMutex();
	}

	~this()
	{
		_mutex.destroy();
	}

	bool set(string key, ubyte[] value)
	{
		checkPath(key);
		_mutex.writer.lock();
		scope(exit) _mutex.writer.unlock();

		stdFile.write(key,value);

		return true;
	}

	bool set(string key,string value)
	{
		return set(key,cast(ubyte[])value);
	}

	T get(T)(string key)
	{
		return cast(T)get(key);
	}

	string get(string key)
	{
		if(!isset(key))return null;
		_mutex.reader.lock();
		scope(exit) _mutex.reader.unlock();
		ubyte[] data = cast(ubyte[])stdFile.read(key);
		return cast(string)(data);
	}

	bool isset(string key)
	{
		if(stdFile.exists(key))return true;
		return false;
	}

	bool erase(string key)
	{
		_mutex.writer.lock();
		scope(exit) _mutex.writer.unlock();

		stdFile.remove(key);
		
		return true;
	}

	bool flush()
	{
		return true;
	}

	void checkPath(string path)
	{
		if(!stdFile.exists(path))stdFile.mkdirRecurse(stdPath.dirName(path));
	}

	void setDefaultHost(string host,ushort port)
	{
	}
}
