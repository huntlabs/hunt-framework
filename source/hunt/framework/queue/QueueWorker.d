module hunt.framework.queue.QueueWorker;

import hunt.framework.queue.Job;
import hunt.framework.queue.Queue;

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

import core.thread;
import std.parallelism;

/**
 * 
 */
abstract class QueueWorker {
    enum string Memory = "momory";
    enum string Redis = "redis";
    enum string AMQP = "amqp";

    private shared bool _isExecuting = true;
    private Thread _workerThread;

    this() {
        launchWorkerThread();
    }

    private void launchWorkerThread() {
        _isExecuting = true;
        _workerThread = new Thread(&executeJob);
        _workerThread.start();
    }

    private void executeJob() {
        while(_isExecuting) {
            Job job = retrieveNextJob(); 
            version(HUNT_DEBUG) tracef("executing a job: %d, status: %s", job.id, job.status);

            if(job.status == JobStatus.READY) {
                auto jobTask = task(&job.exec);
                taskPool.put(jobTask);
            } else {
                warning("dropping a job, status: %s", job.status);
            }
        }
    }

    protected Job retrieveNextJob();

    void push(string channel, Job job);

    void stop() {
        _isExecuting = false;
    }
}

import std.concurrency : initOnce;
import hunt.framework.queue.MemoryQueueWorker;

private __gshared QueueWorker _queueWorker;


deprecated("Using queueWorker instead.") alias taskManager = queueWorker;

QueueWorker queueWorker() {
    return initOnce!(_queueWorker)(new MemoryQueueWorker());
}


void resetQueueWorker(string typeName) {
    if(typeName == QueueWorker.Memory) {
        _queueWorker = new MemoryQueueWorker();
    } else {
        // TODO: Tasks pending completion -@zhangxueping at 2020-04-02T16:43:39+08:00
        // 
        warningf("TODO: %s", typeName);
    }
}
