module hunt.framework.queue.MemoryQueueWorker;

import hunt.framework.queue.Job;
import hunt.framework.queue.QueueWorker;

import hunt.concurrency.SimpleQueue;
import hunt.logging.ConsoleLogger;

import core.thread;
import std.parallelism;

/**
 * 
 */
class MemoryQueueWorker : QueueWorker {
    private SimpleQueue!(ubyte[])[string] _queueMap;

    this() {
        super();
    }

    override void onListen() {
        if(listeners is null) {
            return;
        }
        
        foreach(string channel, QueueMessageListener listener; listeners) {
            auto itemPtr = channel in _queueMap;
            if(itemPtr is null) {
                // version(HUNT_DEBUG) warningf("Can't find channel: %s", channel);
                _queueMap[channel] = new SimpleQueue!(ubyte[])();
                itemPtr = channel in _queueMap;
            }

            ubyte[] content = itemPtr.dequeue();
            version(HUNT_FM_DEBUG) {
                tracef("channel: %s Message: %s", channel, msg.bodyAsString());
                tracef("%(%02X %)", content);
            }
            
            if(listener !is null) {
                listener(content);
            }
        }
    }

    override void push(string channel, ubyte[] message) {
        synchronized(this) {
            auto itemPtr = channel in _queueMap;
            if(itemPtr is null) {
                _queueMap[channel] = new SimpleQueue!(ubyte[])();
                itemPtr = channel in _queueMap;
            }

            itemPtr.enqueue(message);
        }
    }

    override protected void onStop() {
        _queueMap.clear();
    }
}

