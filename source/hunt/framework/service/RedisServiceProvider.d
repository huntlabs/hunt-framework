module hunt.framework.service.RedisServiceProvider;

import hunt.framework.service.ServiceProvider;
import hunt.framework.application.ApplicationConfig;

import hunt.logging.ConsoleLogger;
import hunt.redis;
import poodinis;

/**
 * 
 */
class RedisServiceProvider : ServiceProvider {

    override void register() {
        container.register!(RedisPoolConfig)().singleInstance();
        container.register!(RedisPool)({
            ApplicationConfig config = container.resolve!ApplicationConfig();

            auto redisSettings = config.redis;
            if (redisSettings.pool.enabled) {
                //  new RedisPoolConfig();
                RedisPoolConfig poolConfig = container.resolve!RedisPoolConfig(); 
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
        warning("Booting redis...");
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