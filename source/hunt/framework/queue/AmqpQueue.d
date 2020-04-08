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
    // private AmqpPool _pool;
    private AmqpClient _client;
    private AmqpConnection[QueueMessageListener] _connections;

    this(AmqpClient client) {
        _client = client;
    }
    
    override protected void onListen(string channel, QueueMessageListener listener) {
        if(listeners is null) {
            return;
        }
        
        // AmqpConnection conn = _pool.borrowObject();
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

                        // scope(exit) {
                        //     _pool.returnObject(conn);
                        // }

                        if(listener !is null) {
                            listener(content);
                        }
                        
                        // conn.close(null);
                    }
                });          
            }
        });
        // dfmt on
    }

    override protected void onRemove(string channel, QueueMessageListener listener) {
        auto itemPtr = listener  in _connections;
        if(itemPtr !is null) {
            tracef("Removing a listener from channel %s", channel);
            // _pool.returnObject(*itemPtr);
            itemPtr.close(null);
        }
    }

    override protected void onStop() {
        // if(conn !is null) {
        //     _pool.returnObject(conn);
        // }
    }

    override void push(string channel, ubyte[] message) {
        // AmqpConnection conn = _pool.borrowObject();
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
                // _pool.returnObject(conn);
                conn.close(null);
            }
        });
        // dfmt on
    }
}