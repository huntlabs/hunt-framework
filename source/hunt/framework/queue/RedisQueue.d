module hunt.framework.queue.RedisQueue;

import hunt.framework.queue.AbstractQueue;

import hunt.collection.List;
import hunt.redis.Redis;
import hunt.redis.RedisPool;
import hunt.Long;
import hunt.logging.Logger;

import core.thread;
import std.parallelism;

/**
 * https://blog.rapid7.com/2016/05/04/queuing-tasks-with-redis/
 * https://danielkokott.wordpress.com/2015/02/14/redis-reliable-queue-pattern/
 * https://blog.csdn.net/qq_34212276/article/details/78455004
 */
class RedisQueue : AbstractQueue {
    private RedisPool _pool;
    private Redis[QueueMessageListener] _connections;

    enum string BACKUP_CHANNEL_POSTFIX = "_backup"; // backup channel

    this(RedisPool pool) {
        _pool = pool;
        super(ThreadMode.Multi);
    }

    override void push(string channel, ubyte[] message) {
        Redis redis = _pool.borrow();
        scope(exit) {
            // _pool.returnResource(redis);
            redis.close();
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

    override protected void onListen(string channel, QueueMessageListener listener) {
        assert(listeners !is null);

        Redis redis = _pool.borrow();
        synchronized(this) {
            _connections[listener] = redis; 
        }
        
        version(HUNT_DEBUG) infof("waiting .....");
        string backupChannel = channel ~ BACKUP_CHANNEL_POSTFIX;
        const(ubyte)[] r = redis.brpoplpush(cast(const(ubyte)[])channel, 
            cast(const(ubyte)[])backupChannel, 0); 

        version(HUNT_DEBUG) {
            tracef("channel: %s Message: %s", channel, cast(string)r);
            // tracef("%(%02X %)", r);
        }

        try {
            listener(cast(ubyte[])r);
            Long v = redis.lrem(cast(const(ubyte)[])backupChannel, 1, r);
            version(HUNT_REDIS_DEBUG) {
                if(r is null) {
                    warning("result is null");
                } else {
                    infof("count: %d", v.value());
                }
            }
        } catch (Exception ex) {
            warning(ex.msg);
            version(HUNT_DEBUG) warning(ex);
        }

    }

    override protected void onRemove(string channel, QueueMessageListener listener) {
        auto itemPtr = listener  in _connections;
        if(itemPtr !is null) {
            tracef("Removing a listener from channel %s", channel);
            itemPtr.close();
        }
    }
    
    override protected void onStop() {
        synchronized(this) {
            foreach (Redis redis; _connections) {
                redis.close();
            }
        }
    }
}

