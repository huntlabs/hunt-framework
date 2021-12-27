module hunt.framework.queue.RedisQueue;

import hunt.framework.task.SerializableTask;

import hunt.util.worker.Task;

import hunt.collection.List;
import hunt.redis.Redis;
import hunt.redis.RedisPool;
import hunt.Long;
import hunt.logging;

import core.thread;


alias RedisTaskBuilder = SerializableTask delegate();

/**
 * https://blog.rapid7.com/2016/05/04/queuing-tasks-with-redis/
 * https://danielkokott.wordpress.com/2015/02/14/redis-reliable-queue-pattern/
 * https://blog.csdn.net/qq_34212276/article/details/78455004
 */
class RedisQueue : TaskQueue {
    private string _channel;
    private RedisPool _pool;
    private RedisTaskBuilder _taskBuilder;

    enum string BACKUP_CHANNEL_POSTFIX = "_backup"; // backup channel

    this(RedisPool pool) {
        _channel = "default-queue";
        _pool = pool;
        _taskBuilder = &buildTask;
    }

    string channel() {
        return _channel;
    }

    void channel(string value) {
        _channel = value;
    }

    protected SerializableTask buildTask() {
        return new SerializableTask();
    }

    void taskBuilder(RedisTaskBuilder value) {
        assert(value !is null);
        _taskBuilder = value;
    }

    override void push(Task task) {
        SerializableTask redisTask = cast(SerializableTask)task;

        if(redisTask is null) {
            throw new Exception("Only SerializableTask supported");
        }

        ubyte[] message = redisTask.serialize();

        Redis redis = _pool.borrow();
        scope(exit) {
            _pool.returnObject(redis);
            // redis.close();
        }

        Long r = redis.lpush(cast(const(ubyte)[])channel, cast(const(ubyte)[])message);
        version(HUNT_REDIS_DEBUG) {
            if(r is null) {
                warning("result is null");
            } else {
                infof("count: %d", r.value());
            }
        }
    }

    override bool isEmpty() {
        return false;
    }

    override Task pop() {

        Redis redis = _pool.borrow() ;
        scope(exit) {
            _pool.returnObject(redis);
            // redis.close();
        }
        
        version(HUNT_DEBUG) infof("waiting .....");
        string backupChannel = channel ~ BACKUP_CHANNEL_POSTFIX;
        const(ubyte)[] resultMessage = redis.brpoplpush(cast(const(ubyte)[])channel, 
            cast(const(ubyte)[])backupChannel, 0); 

        version(HUNT_DEBUG) {
            tracef("channel: %s Message: %s", channel, cast(string)resultMessage);
            // tracef("%(%02X %)", r);
        }

        SerializableTask task;
        try {
            task = _taskBuilder();

            Long v = redis.lrem(cast(const(ubyte)[])backupChannel, 1, resultMessage);
            version(HUNT_REDIS_DEBUG) {
                if(resultMessage is null) {
                    warning("result is null");
                } else {
                    infof("count: %d", v.value());
                }
            }

        } catch (Exception ex) {
            warning(ex.msg);
            version(HUNT_DEBUG) warning(ex);
            task = new SerializableTask();
        }

        task.deserialize(resultMessage);
        return task;
    }
}

