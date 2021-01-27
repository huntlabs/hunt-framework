module hunt.framework.queue.QueueManager;

import hunt.framework.config.ApplicationConfig;
import hunt.framework.queue.RedisQueue;
import hunt.util.worker.Task;

import hunt.redis;
import hunt.logging.ConsoleLogger;
import hunt.framework.provider.ServiceProvider;



/**
 * 
 */
class QueueManager {

    enum string MEMORY = "memory";
    enum string REDIS = "redis";

    private ApplicationConfig _config;

    this(ApplicationConfig config) {
        _config = config;
    }

    TaskQueue build() {
        TaskQueue _queue;

        string typeName = _config.queue.driver;
        if (typeName == MEMORY) {
            _queue = new MemoryTaskQueue();
        } else if (typeName == REDIS) {
            RedisPool pool = serviceContainer.resolve!RedisPool();
            _queue = new RedisQueue(pool);
        } else {
            warningf("No queue driver defined %s", typeName);
        }

        return _queue;
    }
}