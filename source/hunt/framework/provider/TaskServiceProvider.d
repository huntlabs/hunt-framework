module hunt.framework.provider.TaskServiceProvider;

import hunt.framework.config.ApplicationConfig;
import hunt.framework.provider.ServiceProvider;
import hunt.framework.queue;
// import hunt.framework.task;
import hunt.util.worker.Worker;

import hunt.logging.ConsoleLogger;
import poodinis;

import std.path;

/**
 * 
 */
class TaskServiceProvider : ServiceProvider {

    private ApplicationConfig _appConfig;

    override void register() {
        container.register!(Worker)(&build).singleInstance();
    }

    protected Worker build() {
        _appConfig = container.resolve!ApplicationConfig();
        if(_appConfig.queue.enabled) {
            QueueManager manager = new QueueManager(_appConfig);
            TaskQueue queue = manager.build();
            return new Worker(queue, _appConfig.queue.workerThreads);
        } else {
            return null;
        }
    }

}