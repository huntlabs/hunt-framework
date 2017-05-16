module hunt.storage.driver.memcache;

version(USE_MEMCACHE){
	public import driveMemcache = memcache;

	@property MemcacheInstance()
	{
		if(_memcached is null)
		{
			_memcached = new driveMemcache.Memcache();
			if(_host.length > 0)
				_memcached.addServer(_host,_port);
		}
		return  _memcached;
	}

	bool addMemcahedHost(string host, ushort port)
	{

		return Memcache.addServer(host,port);
	}

	void setDefaultHost(string host, ushort port)
	{
		_host = host;
		_port = port;
	}

	private:
	driveMemcache.Memcache _memcached = null;

	__gshared string _host;
	__gshared ushort _port;
}
