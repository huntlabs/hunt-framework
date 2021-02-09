module hunt.framework.provider.QueueServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.queue;

import hunt.redis;
import hunt.logging.ConsoleLogger;

import poodinis;

/**
 * 
 */
class QueueServiceProvider : ServiceProvider {

    override void register() {
        container.register!(TaskQueue)(&build).singleInstance();
    }

    protected TaskQueue build() {
        ApplicationConfig config = container.resolve!ApplicationConfig();
        if(config.queue.enabled) {
            QueueManager manager = new QueueManager(config);
            return manager.build();
        } else {
            // return null;
            throw new Exception("Queue is disabled.");
        }
    }
}
