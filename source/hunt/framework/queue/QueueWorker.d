module hunt.framework.queue.QueueWorker;

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

import hunt.framework.queue.Job;
import hunt.logging.ConsoleLogger;

import core.atomic;
import core.thread;
import std.parallelism;

alias QueueMessageListener = void delegate(ubyte[] message);

/**
 * 
 */
abstract class QueueWorker {
    enum string Memory = "memory";
    enum string Redis = "redis";
    enum string AMQP = "amqp";

    private shared bool _isListening = false;
    private QueueMessageListener[string] _listeners;

    this() {
    }

    void push(string channel, ubyte[] message);

    void startListening() {
        if(cas(&_isListening, false, true)) {
            onListen();
        } else {
            warning("Already listening");
        }
    }

    bool addListener(string channel, QueueMessageListener listener) {
        assert(listener !is null);
        
        synchronized(this) {
            auto itemPtr = channel in _listeners;
            if(itemPtr is null) {
                _listeners[channel] = listener;
                return true;
            } else {
                warning("The listener exists for channel %s", channel);
                return false;
            }
        }
    }

    void remove(string channel) {
        synchronized(this) {
            auto itemPtr = channel in _listeners;
            if(itemPtr !is null) {
                _listeners.remove(channel);
            }
        }
    }

    void stop() {
        _isListening = false;
        onStop();
    }

    protected QueueMessageListener[string] listeners() {
        return _listeners;
    }

    protected void onListen() {

    }

    protected void onStop() {

    }
}

