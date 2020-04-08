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
        super(ThreadMode.Multi);
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
        assert(listeners !is null);
        SimpleQueue!(ubyte[])* itemPtr;

        synchronized(this) {
            itemPtr = channel in _queueMap;
            if(itemPtr is null) {
                _queueMap[channel] = new SimpleQueue!(ubyte[])();
                itemPtr = channel in _queueMap;
            }
        }

        ubyte[] content = itemPtr.dequeue();
        version(HUNT_FM_DEBUG) {
            tracef("channel: %s Message: %s", channel, cast(string)content);
            // tracef("%(%02X %)", content);
        }
        
        listener(content);
    }

    override protected void onStop() {
        synchronized(this) {
            _queueMap.clear();
        }
    }
}

