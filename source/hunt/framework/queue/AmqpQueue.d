module hunt.framework.queue.AmqpQueue;

import hunt.framework.queue.AbstractQueue;

import hunt.amqp.client;
import hunt.collection.List;
import hunt.logging.ConsoleLogger;

import core.thread;
import std.parallelism;

/**
 * 
 */
class AmqpQueue : AbstractQueue {
    private AmqpClient _client;
    private AmqpConnection[QueueMessageListener] _connections;

    this(AmqpClient client) {
        _client = client;
        super(ThreadMode.Single);
    }

    override void push(string channel, ubyte[] message) {
        AmqpConnection conn = _client.connect();
        
        // dfmt off
        conn.createSender(channel, new class Handler!AmqpSender{
            void handle(AmqpSender sender) {
                if(sender is null) {
                    warning("Unable to create a sender");
                    return;
                }

                sender.send(AmqpMessage.create().withBody(cast(string)message).build());

                version(HUNT_DEBUG) trace("A message sent.");
                conn.close(null);
            }
        });
        // dfmt on
    }
    
    override protected void onListen(string channel, QueueMessageListener listener) {
        assert(listener !is null);
        
        AmqpConnection conn = _client.connect();
        synchronized(this) {
            _connections[listener] = conn; 
        }

        // dfmt off
        conn.createReceiver(channel, new class Handler!AmqpReceiver {
            void handle(AmqpReceiver recv) {    
                if (recv is null) {
                    logWarning("Unable to create a receiver");
                    return;
                }

                recv.handler(new class Handler!AmqpMessage {
                    void handle(AmqpMessage msg) {
                        // ubyte[] content = cast(ubyte[])msg.bodyAsBinary();
                        ubyte[] content = cast(ubyte[])msg.bodyAsString();
                        version(HUNT_DEBUG) {
                            tracef("channel: %s Message: %s", channel, msg.bodyAsString());
                            // tracef("%(%02X %)", content);
                        }

                        try {
                            listener(content);
                        } catch (Exception ex) {
                            warning(ex.msg);
                            // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-04-10T17:45:34+08:00
                            // do something
                        }
                    }
                });          
            }
        });
        // dfmt on
    }

    override protected void onRemove(string channel, QueueMessageListener listener) {
        synchronized(this) {
            auto itemPtr = listener in _connections;
            if(itemPtr !is null) {
                version(HUNT_DEBUG) tracef("Removing a listener from channel %s", channel);
                _connections.remove(listener);
                itemPtr.close(null);
            }
        }
    }

    override protected void onStop() {
        _client.close(null);
    }
}