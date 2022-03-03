module hunt.framework.queue.QueueManager;

import hunt.framework.config.ApplicationConfig;
import hunt.framework.queue;

// import hunt.amqp.client;
import hunt.redis;
import hunt.logging.Logger;
import hunt.framework.provider.ServiceProvider;

/**
 * 
 */
class QueueManager {
    private ApplicationConfig _config;

    this(ApplicationConfig config) {
        _config = config;
    }

    AbstractQueue build() {
        AbstractQueue _queue;

        string typeName = _config.queue.driver;
        if (typeName == AbstractQueue.MEMORY) {
            _queue = new MemoryQueue();
        // } else if (typeName == AbstractQueue.AMQP) {
        //     auto amqpConf = _config.amqp;

        //     // dfmt off
        //     AmqpClientOptions options = new AmqpClientOptions()
        //         .setHost(amqpConf.host)
        //         .setPort(amqpConf.port)
        //         .setUsername(amqpConf.username)
        //         .setPassword(amqpConf.password);
        //     // dfmt on
            
        //     AmqpClient client = AmqpClient.create(options);
        //     _queue = new AmqpQueue(client);
        } else if (typeName == AbstractQueue.REDIS) {
            RedisPool pool = serviceContainer.resolve!RedisPool();
            _queue = new RedisQueue(pool);
        } else {
            warningf("No queue driver defined %s", typeName);
        }

        return _queue;
    }
}