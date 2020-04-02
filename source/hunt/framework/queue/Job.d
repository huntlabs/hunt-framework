module hunt.framework.queue.Job;

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


enum JobStatus : ubyte {
    READY,
    RUNNING,
    FINISH,
    CANCELED,
    INVAILD,
}


/**
 * 
 */
abstract class Job {

    this() {
        _id = toHash();
    }

    /**
     * Fire the job.
     */
    abstract void exec();

    final @property size_t id() {
        return _id;
    }

    final @property JobStatus status() {
        return atomicLoad(_status);
    }

    final void setStatus(JobStatus ts) {
        atomicStore(_status, ts);
    }

    final @property bool cancel() {
        // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-04-02T18:07:10+08:00
        // 
        if (atomicLoad(_status) == JobStatus.RUNNING)
            return false;
        atomicStore(_status, JobStatus.CANCELED);
        return true;
    }

    private size_t _id;
    private shared JobStatus _status = JobStatus.READY;
}
