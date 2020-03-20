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

            auto redisSettings = config.redis;
            if (redisSettings.pool.enabled) {
                RedisPoolConfig poolConfig = new RedisPoolConfig();
                // RedisPoolConfig poolConfig = container.resolve!RedisPoolConfig(); 
                poolConfig.host = redisSettings.host;
                poolConfig.port = cast(int) redisSettings.port;
                poolConfig.password = redisSettings.password;
                poolConfig.database = cast(int) redisSettings.database;
                poolConfig.soTimeout = cast(int) redisSettings.pool.maxIdle;

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

        // auto redisSettings = config.redis;
        // if (redisSettings.pool.enabled) {
        //     //  new RedisPoolConfig();
        //     RedisPoolConfig poolConfig = container.resolve!RedisPoolConfig(); 
        //     poolConfig.host = redisSettings.host;
        //     poolConfig.port = cast(int) redisSettings.port;
        //     poolConfig.password = redisSettings.password;
        //     poolConfig.database = cast(int) redisSettings.database;
        //     poolConfig.soTimeout = cast(int) redisSettings.pool.maxIdle;

        //     RedisPool pool = container.resolve!RedisPool();
        //     pool.initPool(poolConfig);
        // }
    }
}