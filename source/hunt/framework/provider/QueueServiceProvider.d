module hunt.framework.provider.QueueServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.queue;

import hunt.amqp.client;
import hunt.redis;
import hunt.logging.ConsoleLogger;

import poodinis;

/**
 * 
 */
class QueueServiceProvider : ServiceProvider {

    override void register() {
        container.register!(AbstractQueue)(&buildWorkder).singleInstance();
    }

    protected AbstractQueue buildWorkder() {
        ApplicationConfig config = container.resolve!ApplicationConfig();
        QueueManager manager = new QueueManager(config);
        return manager.build();
    }
}
