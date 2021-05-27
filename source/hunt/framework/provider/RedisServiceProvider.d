module hunt.framework.provider.RedisServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;

import hunt.collection.HashSet;
import hunt.collection.Set;
import hunt.logging.ConsoleLogger;
import hunt.redis;
import poodinis;

import std.conv;
import std.string;

/**
 * 
 */
class RedisServiceProvider : ServiceProvider {

    override void register() {
        // container.register!(RedisPoolConfig)().singleInstance();

        container.register!(RedisPool)(() {
            ApplicationConfig config = container.resolve!ApplicationConfig();

            auto redisOptions = config.redis;
            auto redisPoolOptions = redisOptions.pool;

            if (redisOptions.enabled) {
                RedisPoolConfig poolConfig = new RedisPoolConfig();
                poolConfig.host = redisOptions.host;
                poolConfig.port = cast(int) redisOptions.port;
                poolConfig.password = redisOptions.password;
                poolConfig.database = cast(int) redisOptions.database;
                poolConfig.soTimeout = cast(int) redisPoolOptions.idleTimeout;
                poolConfig.connectionTimeout =  redisOptions.timeout;
                poolConfig.setMaxTotal(redisPoolOptions.maxPoolSize);
                poolConfig.setBlockWhenExhausted(redisPoolOptions.blockOnExhausted);
                poolConfig.setMaxWaitMillis(redisPoolOptions.waitTimeout);

                infof("Initializing RedisPool: %s", poolConfig.toString());

                return new RedisPool(poolConfig); 
            } else {
                // warning("RedisPool has been disabled.");
                // return new RedisPool();
                throw new Exception("The Redis is disabled.");
            }
        }).singleInstance();

        container.register!(RedisCluster)(() {
            ApplicationConfig config = container.resolve!ApplicationConfig();

            auto redisOptions = config.redis;
            auto redisPoolOptions = redisOptions.pool;
            auto clusterOptions = config.redis.cluster;

            if(clusterOptions.enabled) {

                RedisPoolConfig poolConfig = new RedisPoolConfig();
                poolConfig.host = redisOptions.host;
                poolConfig.port = cast(int) redisOptions.port;
                poolConfig.password = redisOptions.password;
                poolConfig.database = cast(int) redisOptions.database;
                poolConfig.soTimeout = cast(int) redisOptions.timeout;
                poolConfig.connectionTimeout =  redisOptions.timeout;
                poolConfig.setMaxTotal(redisPoolOptions.maxPoolSize);
                poolConfig.setBlockWhenExhausted(redisPoolOptions.blockOnExhausted);
                poolConfig.setMaxWaitMillis(redisPoolOptions.waitTimeout);

                infof("Initializing RedisCluster: %s", poolConfig.toString());  

                string[] hostPorts = clusterOptions.nodes;
                Set!(HostAndPort) clusterNode = new HashSet!(HostAndPort)();
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
                        clusterNode.add(new HostAndPort(hostPort[0], port));
                    } catch(Exception ex) {
                        warning(ex);
                    }
                }

                RedisCluster jc = new RedisCluster(clusterNode, redisOptions.timeout, redisOptions.timeout,
                        clusterOptions.redirections, redisOptions.password, poolConfig);

                return jc;

            } else {
                throw new Exception("The RedisCluster is disabled.");
            }

        // }).newInstance();
        }).singleInstance();
    }
}