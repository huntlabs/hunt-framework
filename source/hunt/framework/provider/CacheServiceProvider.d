module hunt.framework.provider.CacheServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;

import hunt.cache.CacheFactory;
import hunt.cache.Cache;
import hunt.framework.Init;

import poodinis;

/**
 * 
 */
class CacheServiceProvider : ServiceProvider {

    override void register() {
        container.register!(Cache)(() {
            ApplicationConfig config = container.resolve!ApplicationConfig();
            return CacheFactory.create(config.cache);
        }).singleInstance();
    }
}