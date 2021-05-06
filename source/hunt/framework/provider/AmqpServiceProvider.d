module hunt.framework.provider.AmqpServiceProvider;

import hunt.framework.provider.ServiceProvider;
import hunt.framework.config.ApplicationConfig;

import hunt.amqp.client;
import hunt.logging.ConsoleLogger;
import poodinis;

import core.time;

/**
 * 
 */
class AmqpServiceProvider : ServiceProvider {

    override void register() {
        container.register!(AmqpClient, AmqpClientImpl).initializedBy!(AmqpClient)({
            ApplicationConfig config = container.resolve!ApplicationConfig();

            auto amqpConfig = config.amqp;
            if (amqpConfig.enabled) {
                AmqpClientOptions options = new AmqpClientOptions();
                options.setHost(amqpConfig.host);
                options.setPort(cast(int) amqpConfig.port);
                options.setPassword(amqpConfig.password);
                options.setUsername(amqpConfig.username);
                options.setConnectTimeout(amqpConfig.timeout.msecs);
                options.setIdleTimeout(amqpConfig.timeout.msecs);

                return AmqpClient.create(options); 
            } else {
                // warning("The AMQP Client has been disabled.");
                // return AmqpClient.create(new AmqpClientOptions());
                throw new Exception("The AMQP Client is disabled.");
            }
        }).singleInstance();
    }

}