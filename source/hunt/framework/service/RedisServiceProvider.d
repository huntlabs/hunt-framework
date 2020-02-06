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
        // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-02-06T14:40:43+08:00
        // using a lazy initializer.
        container.register!(RedisPool)().singleInstance();
    }

    override void boot() {
        warning("Booting redis...");
        ApplicationConfig config = container.resolve!ApplicationConfig();

        auto redisSettings = config.redis;
        if (redisSettings.pool.enabled) {
            RedisPoolConfig poolConfig = container.resolve!RedisPoolConfig(); //  new RedisPoolConfig();
            poolConfig.host = redisSettings.host;
            poolConfig.port = cast(int) redisSettings.port;
            poolConfig.password = redisSettings.password;
            poolConfig.database = cast(int) redisSettings.database;
            poolConfig.soTimeout = cast(int) redisSettings.pool.maxIdle;

            RedisPool pool = container.resolve!RedisPool();
            pool.initPool(poolConfig);
        }
    }
}