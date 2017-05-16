module hunt.storage.driver.memcache;

version(USE_MEMCACHE){
	public import driveMemcache = memcache;

	@property MemcacheInstance()
	{
		if(_memcache is null)
		{
			_memcache = new driveMemcache.Memcache();
			if(_host.length > 0)
				_memcache.addServer(_host,_port);
		}
		return  _memcache;
	}

	bool addMemcahedHost(string host, ushort port)
	{

		return MemcacheInstance.addServer(host,port);
	}

	void setDefaultHost(string host, ushort port)
	{
		_host = host;
		_port = port;
	}

	private:
	driveMemcache.Memcache _memcache = null;

	__gshared string _host;
	__gshared ushort _port;
}
