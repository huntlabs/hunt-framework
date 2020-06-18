module hunt.framework.provider.DatabaseServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;

import hunt.logging.ConsoleLogger;
import hunt.entity;
import poodinis;

/**
 * 
 */
class DatabaseServiceProvider : ServiceProvider {

    override void register() {
        container.register!(EntityManagerFactory)(&buildEntityManagerFactory)
            .singleInstance();
    }

    private EntityManagerFactory buildEntityManagerFactory() {
        ApplicationConfig appConfig = container.resolve!ApplicationConfig();
        ApplicationConfig.DatabaseConf config = appConfig.database;

        if (config.enabled) {

            import hunt.entity.EntityOption;

            auto option = new EntityOption;

            // database options
            option.database.driver = config.driver;
            option.database.host = config.host;
            option.database.username = config.username;
            option.database.password = config.password;
            option.database.port = config.port;
            option.database.database = config.database;
            option.database.charset = config.charset;
            option.database.prefix = config.prefix;

            // database pool options
            option.pool.minIdle = config.pool.minIdle;
            option.pool.idleTimeout = config.pool.idleTimeout;
            option.pool.maxPoolSize = config.pool.maxPoolSize;
            option.pool.minPoolSize = config.pool.minPoolSize;
            option.pool.maxLifetime = config.pool.maxLifetime;
            option.pool.connectionTimeout = config.pool.connectionTimeout;
            option.pool.maxConnection = config.pool.maxConnection;
            option.pool.minConnection = config.pool.minConnection;

            infof("using database: %s", config.driver);
            return Persistence.createEntityManagerFactory(option);
        } else {
            warning("The database is disabled.");
            return null;
        }
    }

    override void boot() {
        EntityManagerFactory factory = container.resolve!EntityManagerFactory();
    }
}