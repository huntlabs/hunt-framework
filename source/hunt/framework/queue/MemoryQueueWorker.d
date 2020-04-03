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
// class MemoryQueueWorker : QueueWorker {
//     private SimpleQueue!Job _jobs;

//     this() {
//         _jobs = new SimpleQueue!Job();
//         super();
//     }

//     override protected Job retrieveNextJob() {
//         return _jobs.dequeue();
//     }

//     override void push(string channel, ubyte[] message) {
//         _jobs.enqueue(job);
//     }
// }