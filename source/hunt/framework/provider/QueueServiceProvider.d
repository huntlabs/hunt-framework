module hunt.framework.provider.QueueServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.queue;

import hunt.amqp.client;
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
        AbstractQueue _queue;
        ApplicationConfig config = container.resolve!ApplicationConfig();

        string typeName = config.queue.driver;

        if (typeName == AbstractQueue.Memory) {
            _queue = new MemoryQueue();
        } else if (typeName == AbstractQueue.AMQP) {
            auto amqpConf = config.amqp;

            AmqpClientOptions options = new AmqpClientOptions()
            .setHost(amqpConf.host)
            .setPort(amqpConf.port)
            .setUsername(amqpConf.username)
            .setPassword(amqpConf.password);

            AmqpPool pool = new AmqpPool(options);
            _queue = new AmqpQueue(pool);
        } else {
            // TODO: Tasks pending completion -@zhangxueping at 2020-04-02T16:43:39+08:00
            // 
            warningf("No queue driver defined %s", typeName);
        }

        return _queue;
    }
}
