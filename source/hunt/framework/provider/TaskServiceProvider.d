module hunt.framework.provider.TaskServiceProvider;

import hunt.framework.config.ApplicationConfig;
import hunt.framework.provider.ServiceProvider;
import hunt.framework.queue;
import hunt.framework.task;

import hunt.logging.ConsoleLogger;
import poodinis;

import std.path;

/**
 * 
 */
class TaskServiceProvider : ServiceProvider {

    private ApplicationConfig _appConfig;

    override void register() {

        container.register!(TaskWorker).initializedBy(() {
            AbstractQueue queue = serviceContainer.resolve!(AbstractQueue);
            return new TaskWorker(queue);
        }).newInstance();
    }

    override void boot() {
        _appConfig = container.resolve!ApplicationConfig();
    }
}