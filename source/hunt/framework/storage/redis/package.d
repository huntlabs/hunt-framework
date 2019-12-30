module hunt.framework.storage.redis;

import hunt.redis;
import hunt.framework.Simplify;
import hunt.logging;

private Redis _redis;
private RedisCluster _redisCluster;

Redis getRedis(bool fromPool = false)() {
    static if(fromPool) {
        return defaultRedisPool.getResource();
    } else {
        if (_redis is null || _redis.getClient().isBroken()) {
            auto redisSettings = config().redis;
            version (HUNT_DEBUG) {
                tracef("Create a redis connection with %s:%d, password:%s", 
                    redisSettings.host, redisSettings.port, redisSettings.password);
            }

            if (redisSettings.enabled) {
                _redis = new Redis(redisSettings.host, redisSettings.port, redisSettings.timeout, redisSettings.timeout);
                _redis.connect();
                if (redisSettings.password.length > 0)
                    _redis.auth(redisSettings.password);
                _redis.select(redisSettings.database);
            } else {
                warning("Please set config hunt.redis.enabled = true");
            }
        }

        return _redis;
    }
}

/**
 * 
 */
RedisCluster getRedisFromCluster() {
    
    if(_redisCluster is null) {
        import hunt.pool.impl.GenericObjectPoolConfig;
        import std.string;
        import std.conv;

        enum int DEFAULT_REDIRECTIONS = 5;
        enum int DEFAULT_TIMEOUT = 2000;
        auto poolConfig = new GenericObjectPoolConfig();

        auto redisSettings = config().redis;
        assert(redisSettings.cluster.enabled, "Please set `hunt.redis.cluster.enabled = true`");

        string[] nodes = redisSettings.cluster.nodes;
        assert(nodes.length > 0, "No nodes set");

        string[] nodeAddress = nodes[0].split(":");
        string host = nodeAddress[0];
        int port = 6379;
        if(nodeAddress.length >1) {
            port = nodeAddress[1].to!int();
        }

        version(HUNT_DEBUG) {
            infof("Redis cluster node: %s", nodes[0]);
        }

        int timeout = redisSettings.timeout;
        if(timeout <= 0) {
            timeout = DEFAULT_TIMEOUT;
        }

        _redisCluster = new RedisCluster(new HostAndPort(host, port), 
            timeout, timeout, DEFAULT_REDIRECTIONS, 
            redisSettings.password, poolConfig);
    }

    return _redisCluster;
}
