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

module hunt.storage.redis;
version(USE_REDIS){
	public import driveRedis = redis;
	@property Redis()
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
	driveRedis.Redis _redis = null;

	__gshared string _host = "127.0.0.1";
	__gshared ushort _port = 6379;
}
