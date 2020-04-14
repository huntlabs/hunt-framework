module hunt.framework.provider.RedisServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;

import hunt.logging.ConsoleLogger;
import hunt.redis;
import poodinis;

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

            if (redisOptions.pool.enabled) {
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
                warning("RedisPool has been disabled.");
                return new RedisPool();
            }
        }).singleInstance();
    }

    override void boot() {
        // trace("Booting redis...");
        // ApplicationConfig config = container.resolve!ApplicationConfig();

        // auto redisOptions = config.redis;
        // if (redisOptions.pool.enabled) {
        //     //  new RedisPoolConfig();
        //     RedisPoolConfig poolConfig = container.resolve!RedisPoolConfig(); 
        //     poolConfig.host = redisOptions.host;
        //     poolConfig.port = cast(int) redisOptions.port;
        //     poolConfig.password = redisOptions.password;
        //     poolConfig.database = cast(int) redisOptions.database;
        //     poolConfig.soTimeout = cast(int) redisOptions.pool.maxIdle;

        //     RedisPool pool = container.resolve!RedisPool();
        //     pool.initPool(poolConfig);
        // }
    }
}