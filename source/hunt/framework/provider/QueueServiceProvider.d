module hunt.framework.provider.QueueServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.queue;

import hunt.redis;
import hunt.logging.Logger;

import poodinis;

/**
 * 
 */
class QueueServiceProvider : ServiceProvider {

    override void register() {
        container.register!(AbstractQueue).initializedBy(&buildWorkder).singleInstance();
    }

    protected AbstractQueue buildWorkder() {
        ApplicationConfig config = container.resolve!ApplicationConfig();
        QueueManager manager = new QueueManager(config);
        return manager.build();
    }
}
