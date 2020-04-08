module hunt.framework.queue.MemoryQueue;

import hunt.framework.queue.AbstractQueue;

import hunt.collection.List;
import hunt.concurrency.SimpleQueue;
import hunt.logging.ConsoleLogger;

import core.thread;
import std.parallelism;

/**
 * 
 */
class MemoryQueue : AbstractQueue {
    private SimpleQueue!(ubyte[])[string] _queueMap;

    this() {
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

    override void onListen(string channel, QueueMessageListener listener) {
        if(listeners is null) {
            return;
        }
        
        // foreach(string channel, List!QueueMessageListener channelListeners; listeners) {
        //     auto itemPtr = channel in _queueMap;
        //     if(itemPtr is null) {
        //         _queueMap[channel] = new SimpleQueue!(ubyte[])();
        //         itemPtr = channel in _queueMap;
        //     }

        //     ubyte[] content = itemPtr.dequeue();
        //     version(HUNT_FM_DEBUG) {
        //         tracef("channel: %s Message: %s", channel, msg.bodyAsString());
        //         tracef("%(%02X %)", content);
        //     }
            
        //     foreach(QueueMessageListener listener; channelListeners) {
        //         listener(content);
        //     }
        // }
    }

    override protected void onStop() {
        _queueMap.clear();
    }
}

