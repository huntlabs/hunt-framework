module hunt.framework.provider.SessionServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.application.ApplicationConfig;

import hunt.framework.http.session.SessionStorage;
import hunt.framework.Init;
import hunt.cache.Cache;

import poodinis;

/**
 * 
 */
class SessionServiceProvider : ServiceProvider {

    override void register() {
        container.register!(SessionStorage)(() {
            ApplicationConfig config = container.resolve!ApplicationConfig();
            Cache cache = container.resolve!Cache;
            return new SessionStorage(cache, config.session.expire);
        }).singleInstance();
    }
}