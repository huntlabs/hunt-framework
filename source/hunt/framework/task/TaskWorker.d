module hunt.framework.task.TaskWorker;

import hunt.framework.task.TaskExecutor;
import hunt.framework.queue;

import hunt.logging.ConsoleLogger;
import hunt.serialization.JsonSerializer;


/**
 * 
 */
class TaskWorker {
    enum string DEFAULT_CHANNEL = "default";

    private AbstractQueue _queue;

    this(AbstractQueue queue) {
        assert(queue !is null);
        _queue = queue;
    }

    void listen(T)() if(is(T : TaskExecutor)) {
        listen!T(DEFAULT_CHANNEL);
    }

    void listen(T)(string channel) if(is(T : TaskExecutor)) {
        _queue.addListener(channel, (ubyte[] message) {
            string msg = cast(string)message;
            version(HUNT_FM_DEBUG) tracef("Received message: %(%02X %)", message);
            try {
                T obj = toObject!(T)(message);
                obj.execute();
            } catch(Exception ex) {
                warning(ex.msg);
                version(HUNT_DEBUG) {
                    warning(ex);
                }
            }
        });
    }

    void dispatch(T)(T task) if(is(T : TaskExecutor)) {
        dispatch(DEFAULT_CHANNEL, task);
    }

    void dispatch(T)(string channel, T task) if(is(T : TaskExecutor)) {
        string message = toJson(task).toString();
        _queue.push(channel, cast(ubyte[])message);
    }
}