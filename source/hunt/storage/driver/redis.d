module hunt.storage.driver.redis;

version(USE_REDIS){
	public import driveRedis = redis;
	@property RedisInstance()
	{
		if(_redis is null)
		{
			_redis = new driveRedis.Redis(_host,_port);
		}
		return  _redis;
	}

	void setDefaultHost(string host = "127.0.0.1", ushort port = 6379)
	{
		_host = host;
		_port = port;
	}

	private:
	__gshared driveRedis.Redis _redis = null;

	__gshared string _host = "127.0.0.1";
	__gshared ushort _port = 6379;
}
