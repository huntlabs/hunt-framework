module hunt.framework.provider.CacheServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;

import hunt.cache.CacheFactory;
import hunt.cache.Cache;
import hunt.cache.CacheOptions;
import hunt.cache.Defined;
import hunt.logging.ConsoleLogger;
import hunt.redis.RedisPoolConfig;

import hunt.framework.Init;

import poodinis;

/**
 * 
 */
class CacheServiceProvider : ServiceProvider {

    override void register() {
        container.register!(Cache)(() {
            ApplicationConfig config = container.resolve!ApplicationConfig();
            ApplicationConfig.CacheConf cacheConf = config.cache;
            ApplicationConfig.RedisConf redisConf = config.redis;
            auto redisPoolOptions = redisConf.pool;

            CacheOptions options = new CacheOptions();
            options.adapter = cacheConf.adapter;
            options.prefix = cacheConf.prefix;
            options.useSecondLevelCache = cacheConf.useSecondLevelCache;
            options.maxEntriesLocalHeap = cacheConf.maxEntriesLocalHeap;
            options.eternal = cacheConf.eternal;
            options.timeToIdleSeconds = cacheConf.timeToIdleSeconds;
            options.timeToLiveSeconds = cacheConf.timeToLiveSeconds;
            options.overflowToDisk = cacheConf.overflowToDisk;
            options.diskPersistent = cacheConf.diskPersistent;
            options.diskExpiryThreadIntervalSeconds = cacheConf.diskExpiryThreadIntervalSeconds;
            options.maxEntriesLocalDisk = cacheConf.maxEntriesLocalDisk;

            if(cacheConf.adapter == AdapterType.REDIS) {
                RedisPoolConfig poolConfig = new RedisPoolConfig();
                poolConfig.host = redisConf.host;
                poolConfig.port = cast(int) redisConf.port;
                poolConfig.password = redisConf.password;
                poolConfig.database = cast(int) redisConf.database;
                poolConfig.soTimeout = cast(int) redisPoolOptions.idleTimeout;
                poolConfig.connectionTimeout =  redisConf.timeout;
                poolConfig.setMaxTotal(redisPoolOptions.maxPoolSize);
                poolConfig.setBlockWhenExhausted(redisPoolOptions.blockOnExhausted);
                poolConfig.setMaxWaitMillis(redisPoolOptions.waitTimeout);

                version(HUNT_DEBUG) infof("Initializing RedisPool: %s", poolConfig.toString());

                options.redisPool = poolConfig;

                options.isRedisClusterEnabled = redisConf.cluster.enabled;
                options.redisCluster.nodes = redisConf.cluster.nodes;
            }

            return CacheFactory.create(options);
        }).singleInstance();
    }
}