module hunt.framework.queue.AmqpQueueWorker;

import hunt.framework.queue.Job;
import hunt.framework.queue.QueueWorker;

import hunt.amqp.client;
import hunt.logging.ConsoleLogger;

import core.thread;
import std.parallelism;

/**
 * 
 */
class AmqpQueueWorker : QueueWorker {
    private AmqpPool _pool;
    private AmqpConnection _listenerConn;

    this(AmqpPool pool) {
        _pool = pool;
        super();
    }
    
    override void onListen() {
        if(listeners is null) {
            return;
        }
        
        _listenerConn = _pool.borrowObject();
        // dfmt off
        foreach(string channel, QueueMessageListener listener; listeners) {
            _listenerConn.createReceiver(channel, new class Handler!AmqpReceiver {
                void handle(AmqpReceiver recv) {    
                    if (recv is null) {
                        logWarning("Unable to create a receiver");
                        return;
                    }

                    recv.handler(new class Handler!AmqpMessage {
                        void handle(AmqpMessage msg) {
                            // ubyte[] content = cast(ubyte[])msg.bodyAsBinary();
                            ubyte[] content = cast(ubyte[])msg.bodyAsString();
                            version(HUNT_FM_DEBUG) {
                                tracef("channel: %s Message: %s", channel, msg.bodyAsString());
                                tracef("%(%02X %)", content);
                            }
                            if(listener !is null) {
                                listener(content);
                            }
                        }
                    });          
                }
            });
        }
        // dfmt on
    }

    override void push(string channel, ubyte[] message) {
        AmqpConnection conn = _pool.borrowObject();
        
        // dfmt off
        conn.createSender(channel, new class Handler!AmqpSender{
            void handle(AmqpSender sender) {
                if(sender is null) {
                    warning("Unable to create a sender");
                    return;
                }

                // DateTime dt = cast(DateTime)Clock.currTime();
                // string msg = format("Say hello at %s", dt.toSimpleString());
                // sender.send(AmqpMessage.create().withBody(msg).build());
                sender.send(AmqpMessage.create().withBody(cast(string)message).build());

                trace("A message sent.");
                _pool.returnObject(conn);
            }
        });
        // dfmt on
    }

    override protected void onStop() {
        if(_listenerConn !is null) {
            _pool.returnObject(_listenerConn);
        }
    }
}