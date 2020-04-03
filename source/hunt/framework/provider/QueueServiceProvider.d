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
        container.register!(QueueWorker)(&buildWorkder).singleInstance();
    }

    protected QueueWorker buildWorkder() {
        QueueWorker _queueWorker;
        ApplicationConfig config = container.resolve!ApplicationConfig();

        string typeName = QueueWorker.AMQP;

        if (typeName == QueueWorker.Memory) {
            // _queueWorker = new MemoryQueueWorker();
            warningf("TODO: %s", typeName);
        } else if (typeName == QueueWorker.AMQP) {
            AmqpClientOptions options = new AmqpClientOptions()
            .setHost("10.1.223.62")
            .setPort(5672)
            .setUsername("test")
            .setPassword("123");

            AmqpPool pool = new AmqpPool(options);
            _queueWorker = new AmqpQueueWorker(pool);
        } else {
            // TODO: Tasks pending completion -@zhangxueping at 2020-04-02T16:43:39+08:00
            // 
            warningf("TODO: %s", typeName);
        }

        return _queueWorker;
    }
}
