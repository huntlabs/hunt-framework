module hunt.storage.filestorage;

import hunt.utils.time;
import std.stdio;
import core.memory;
import stdFile = std.file;
import Path = std.path;
import core.sync.rwmutex;

Filestorage _file;
@property File()
{
	if(_file is null)
	{
		_file = new Filestorage;
	}
	return  _file;
}
class Filestorage
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

	/*
	bool flush()
	{
		stdFile.remove(_path);
		return true;
	}

	void setExpire(int exprie)
	{
		this._exprie = exprie;
	}

	bool isExpire(string key)
	{
		int exprie = (cast(int[])stdFile.read(key,4))[0];
		if(exprie == 0)return true;
		if(exprie <= getCurrUnixStramp)
		{
			scope(exit)erase(key);
			return false;
		}else{
			return true;
		}

	}
	void setPath(string path)
	{
		this._path = path;
		if(!stdFile.exists(path))File.mkdirRecurse(Path.dirName(path));
	}
	*/

	void setDefaultHost(string host,ushort port)
	{
	}
}
