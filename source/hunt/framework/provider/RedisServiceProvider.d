module hunt.framework.provider.RedisServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;

import hunt.collection.HashSet;
import hunt.collection.Set;
import hunt.logging;
import hunt.redis;
import poodinis;

import core.time;

import std.conv;
import std.string;

/**
 * 
 */
class RedisServiceProvider : ServiceProvider {

    override void register() {
        // container.register!(RedisPoolOptions)().singleInstance();

        container.register!RedisPool.initializedBy({
            ApplicationConfig config = container.resolve!ApplicationConfig();

            auto redisOptions = config.redis;
            auto redisPoolOptions = redisOptions.pool;

            if (redisOptions.enabled) {
                RedisPoolOptions poolConfig = new RedisPoolOptions();
                poolConfig.host = redisOptions.host;
                poolConfig.port = cast(int) redisOptions.port;
                poolConfig.password = redisOptions.password;
                poolConfig.database = cast(int) redisOptions.database;
                poolConfig.soTimeout = cast(int) redisPoolOptions.idleTimeout;
                poolConfig.connectionTimeout =  redisOptions.timeout;
                poolConfig.size = redisPoolOptions.maxPoolSize;
                poolConfig.maxWaitQueueSize = redisPoolOptions.maxWaitQueueSize;
                poolConfig.waitTimeout = msecs(redisPoolOptions.waitTimeout);

                infof("Initializing RedisPool: %s", poolConfig.toString());

                RedisFactory factory = new RedisFactory(poolConfig);

                return factory.pool(); 
            } else {
                // warning("RedisPool has been disabled.");
                // return new RedisPool();
                throw new Exception("The Redis is disabled.");
            }
        }).singleInstance();

        container.register!RedisCluster.initializedBy({
            ApplicationConfig config = container.resolve!ApplicationConfig();

            auto redisOptions = config.redis;
            auto redisPoolOptions = redisOptions.pool;
            auto clusterOptions = config.redis.cluster;

            if(clusterOptions.enabled) {

                RedisPoolOptions poolConfig = new RedisPoolOptions();
                poolConfig.host = redisOptions.host;
                poolConfig.port = cast(int) redisOptions.port;
                poolConfig.password = redisOptions.password;
                poolConfig.database = cast(int) redisOptions.database;
                poolConfig.soTimeout = cast(int) redisOptions.timeout;
                poolConfig.connectionTimeout =  redisOptions.timeout;
                poolConfig.waitTimeout = msecs(redisPoolOptions.waitTimeout);
                poolConfig.size = redisPoolOptions.maxPoolSize;

                infof("Initializing RedisCluster: %s", poolConfig.toString());  

                string[] hostPorts = clusterOptions.nodes;
                HostAndPort[] clusterNode;
                foreach(string item; hostPorts) {
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

                RedisCluster jc = new RedisCluster(clusterNode, poolConfig);

                return jc;

            } else {
                throw new Exception("The RedisCluster is disabled.");
            }

        // }).newInstance();
        }).singleInstance();
    }
}