module hunt.framework.queue.RedisQueue;

import hunt.framework.queue.AbstractQueue;

import hunt.redis;
import hunt.Long;
import hunt.logging.ConsoleLogger;

import core.thread;
import std.parallelism;

/**
 * https://blog.rapid7.com/2016/05/04/queuing-tasks-with-redis/
 * https://danielkokott.wordpress.com/2015/02/14/redis-reliable-queue-pattern/
 * https://blog.csdn.net/qq_34212276/article/details/78455004
 */
// class RedisQueue : AbstractQueue {
//     private RedisPool _pool;

//     this(RedisPool pool) {
//         _pool = pool;
//         super();
//     }

//     override void onListen() {
//         if(listeners is null) {
//             return;
//         }
        
//         foreach(string channel, QueueMessageListener listener; listeners) {
//             auto itemPtr = channel in _queueMap;
//             if(itemPtr is null) {
//                 _queueMap[channel] = new SimpleQueue!(ubyte[])();
//                 itemPtr = channel in _queueMap;
//             }

//             ubyte[] content = itemPtr.dequeue();
//             version(HUNT_FM_DEBUG) {
//                 tracef("channel: %s Message: %s", channel, msg.bodyAsString());
//                 tracef("%(%02X %)", content);
//             }
            
//             if(listener !is null) {
//                 listener(content);
//             }
//         }
//     }

//     override void push(string channel, ubyte[] message) {

//         hunt.redis.Redis redis = _pool.getResource();
//         scope(exit) {
//             // _pool.returnResource(redis);
//             redis.close();
//         }

//         Long r = redis.lpush(channel, message);
//         if(r is null) {
//             warning("r is null");
//         } else {
//             infof("xxxx=> %d", r.value());
//         }
//     }

//     override protected void onStop() {
//         _queueMap.clear();
//     }
// }

