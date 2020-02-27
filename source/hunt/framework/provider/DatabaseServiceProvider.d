module hunt.framework.provider.DatabaseServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.application.ApplicationConfig;

import hunt.logging.ConsoleLogger;
import hunt.entity;
import poodinis;

/**
 * 
 */
class DatabaseServiceProvider : ServiceProvider {

    override void register() {
        // container.register!(RedisPoolConfig)().singleInstance();

        container.register!(EntityManagerFactory)(&buildEntityManagerFactory)
            .singleInstance();
    }

    private EntityManagerFactory buildEntityManagerFactory() {
        ApplicationConfig appConfig = container.resolve!ApplicationConfig();
        ApplicationConfig.DatabaseConf config = appConfig.database;

        if (config.defaultOptions.enabled) {

            import hunt.entity.EntityOption;

            auto option = new EntityOption;

            // database options
            option.database.driver = config.defaultOptions.driver;
            option.database.host = config.defaultOptions.host;
            option.database.username = config.defaultOptions.username;
            option.database.password = config.defaultOptions.password;
            option.database.port = config.defaultOptions.port;
            option.database.database = config.defaultOptions.database;
            option.database.charset = config.defaultOptions.charset;
            option.database.prefix = config.defaultOptions.prefix;

            // database pool options
            option.pool.minIdle = config.pool.minIdle;
            option.pool.idleTimeout = config.pool.idleTimeout;
            option.pool.maxPoolSize = config.pool.maxPoolSize;
            option.pool.minPoolSize = config.pool.minPoolSize;
            option.pool.maxLifetime = config.pool.maxLifetime;
            option.pool.connectionTimeout = config.pool.connectionTimeout;
            option.pool.maxConnection = config.pool.maxConnection;
            option.pool.minConnection = config.pool.minConnection;

            infof("using database: %s", config.defaultOptions.driver);
            return Persistence.createEntityManagerFactory("default", option);
        } else {
            warning("The database is disabled.");
            return null;
        }
    }
}