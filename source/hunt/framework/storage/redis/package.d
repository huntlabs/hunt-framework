module hunt.framework.storage.redis;

import hunt.redis;
import hunt.framework.Simplify;
import hunt.logging;

private RedisCluster _redisCluster;

Redis getRedis() {
    return defaultRedisPool.borrow();
}

/**
 * 
 */
RedisCluster getRedisFromCluster() {
    
    if(_redisCluster is null) {
        //import hunt.pool.impl.GenericObjectPoolConfig;
        import std.string;
        import std.conv;

        enum int DEFAULT_REDIRECTIONS = 5;
        enum int DEFAULT_TIMEOUT = 2000;
        //auto poolConfig = new GenericObjectPoolConfig();
        RedisPoolOptions redisPool = new RedisPoolOptions();
        auto redisSettings = config().redis;
        assert(redisSettings.cluster.enabled, "Please set `hunt.redis.cluster.enabled = true`");

        string[] nodes = redisSettings.cluster.nodes;
        assert(nodes.length > 0, "No nodes set");
        HostAndPort[] clusterNode;
        
        foreach(string item; nodes) {
            string[] hostPort = item.split(":");
            if(hostPort.length < 2) {
                warningf("Wrong host and port: %s", item);
                continue;
            }

            version(HUNT_DEBUG) {
                tracef("Cluster host: %s", hostPort);
            }

            try {
                int port = to!int(hostPort[1]);
                clusterNode ~= new HostAndPort(hostPort[0], port);
            } catch(Exception ex) {
                warning(ex);
            }
        }
        // string[] nodeAddress = nodes[0].split(":");
        // string host = nodeAddress[0];
        // int port = 6379;
        // if(nodeAddress.length >1) {
        //     port = nodeAddress[1].to!int();
        // }

        // version(HUNT_DEBUG) {
        //     infof("Redis cluster node: %s", nodes[0]);
        // }

        // int timeout = redisSettings.timeout;
        // if(timeout <= 0) {
        //     timeout = DEFAULT_TIMEOUT;
        // }

        // _redisCluster = new RedisCluster(new HostAndPort(host, port), 
        //     timeout, timeout, DEFAULT_REDIRECTIONS, 
        //     redisSettings.password, poolConfig);
        _redisCluster = new RedisCluster(clusterNode, redisPool);
    }

    return _redisCluster;
}
