module hunt.framework.task.Task;

import core.time;

import std.parallelism : atomicLoad, atomicStore;

import hunt.event.timer.common;
import hunt.event.EventLoop;
import hunt.lang.common;
import hunt.util.timer;
import hunt.logging;

enum TaskStatus : ubyte
{
    IDLE,
    RUNNING,
    FINISH,
    CANCEL,
    INVAILD,
}

class Task
{
    alias FinishFunc = void delegate(Task) nothrow;

    this()
    {
        _taskid = toHash();
    }

    abstract void exec()
    {
        trace("please override the 'exec' function !");
    }

    final @property size_t tid()
    {
        return _taskid;
    }

    final @property void setFinish(FinishFunc finish)
    {
        _finishFunc = finish;
    }

    // protected
    // {
        final void setInterval(Duration d)
        {
            _interval = d;
        }

        final @property Duration interval()
        {
            return _interval;
        }

        final @property TaskStatus status()
        {
            return atomicLoad(_status);
        }

        final void setStatus(TaskStatus ts)
        {
            atomicStore(_status, ts);
        }

        final @property bool cancel()
        {
            if (atomicLoad(_status) == TaskStatus.RUNNING)
                return false;
            atomicStore(_status, TaskStatus.CANCEL);
            return true;
        }

        final @property void onFinish()
        {
            if(_finishFunc)
                return _finishFunc(this);
        }
    // }
    
    private
    {
        Duration _interval;
        size_t _taskid;
        shared TaskStatus _status = TaskStatus.IDLE;
        FinishFunc _finishFunc;
    }
}
