module hunt.framework.storage.redis;

import redis;

import hunt.framework.Simplify;

static private Redis _redis;

Redis redis()
{
    if (_redis is null)
    {
        _redis = new Redis(config().redis.host, config().redis.port, config().redis.password);
    }

    return _redis;
}
