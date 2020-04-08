module hunt.framework.queue.AbstractQueue;

// import hunt.framework.queue.Job;

import core.time;
import core.atomic;
import core.sync.rwmutex;

import std.stdio;
import std.parallelism;
import std.variant;
import std.traits;
import std.exception;

import hunt.event.timer.Common;
import hunt.event.EventLoop;
import hunt.util.Common;
import hunt.util.Timer;
import hunt.logging;

import hunt.logging.ConsoleLogger;
import hunt.collection.ArrayList;
import hunt.collection.List;

import core.atomic;
import core.thread;
import std.parallelism;

alias QueueMessageListener = void delegate(ubyte[] message);

/**
 * 
 */
abstract class AbstractQueue {
    enum string MEMORY = "memory";
    enum string REDIS = "redis";
    enum string AMQP = "amqp";

    private shared bool _isListening = false;
    private List!(QueueMessageListener)[string] _listeners;


    void push(string channel, ubyte[] message);

    void addListener(string channel, QueueMessageListener listener) {
        assert(listener !is null);
        
        synchronized(this) {
            List!QueueMessageListener list;
            auto itemPtr = channel in _listeners;
            if(itemPtr is null) {
                list = new ArrayList!QueueMessageListener();
                _listeners[channel] = list;
            } else {
                list = *itemPtr;
            }
            
            list.add(listener);
        }

        // dispatch the listener to a working thread
        auto listenTask = task(&onListen, channel, listener);
        taskPool.put(listenTask);
    }

    protected void onListen(string channel, QueueMessageListener listener);

    void remove(string channel) {
        synchronized(this) {
            auto itemPtr = channel in _listeners;
            if(itemPtr !is null) {
                _listeners.remove(channel);
            }

            foreach(QueueMessageListener listener; *itemPtr) {
                onRemove(channel, listener);
            }
        }
    }
    
    void remove(string channel, QueueMessageListener listener) {
        synchronized(this) {
            auto itemPtr = channel in _listeners;
            if(itemPtr !is null) {
                itemPtr.remove(listener);
            }

            onRemove(channel, listener);
        }
    }

    protected void onRemove(string channel, QueueMessageListener listener) {

    }

    void stop() {
        _isListening = false;
        onStop();
    }

    protected List!(QueueMessageListener)[string] listeners() {
        return _listeners;
    }

    protected void onListen() {

    }

    protected void onStop() {

    }
}

