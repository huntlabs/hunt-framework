module hunt.framework.provider.CacheServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;

import hunt.cache.CacheFactory;
import hunt.cache.Cache;
import hunt.cache.CacheOption;
import hunt.cache.Defined;

import hunt.framework.Init;

import poodinis;

/**
 * 
 */
class CacheServiceProvider : ServiceProvider {

    override void register() {
        container.register!(Cache)(() {
            ApplicationConfig config = container.resolve!ApplicationConfig();
            if(config.cache.adapter == AdapterType.REDIS) {
                config.cache.redis.host = config.redis.host;
                config.cache.redis.port = config.redis.port;
                config.cache.redis.password = config.redis.password;
                config.cache.redis.database = config.redis.database;
                config.cache.redis.timeout = config.redis.timeout;

                config.cache.redis.pool.enabled = config.redis.pool.enabled;
                config.cache.redis.pool.blockOnExhausted = config.redis.pool.blockOnExhausted;
                config.cache.redis.pool.idleTimeout = config.redis.pool.idleTimeout;
                config.cache.redis.pool.maxPoolSize = config.redis.pool.maxPoolSize;
                config.cache.redis.pool.minPoolSize = config.redis.pool.minPoolSize;
                config.cache.redis.pool.maxLifetime = config.redis.pool.maxLifetime;
                config.cache.redis.pool.connectionTimeout = config.redis.pool.connectionTimeout;
                config.cache.redis.pool.waitTimeout = config.redis.pool.waitTimeout;
                config.cache.redis.pool.maxConnection = config.redis.pool.maxConnection;
                config.cache.redis.pool.minConnection = config.redis.pool.minConnection;

                config.cache.redis.cluster.enabled = config.redis.cluster.enabled;
                config.cache.redis.cluster.nodes = config.redis.cluster.nodes;
            }
            
            return CacheFactory.create(config.cache);
        }).singleInstance();
    }
}