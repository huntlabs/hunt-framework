module hunt.framework.task.SerializableTask;


import hunt.util.worker.Task;
import hunt.logging.ConsoleLogger;


class SerializableTask : Task {


    override void doExecute() {
        tracef("Do nothing");
    }

    ubyte[] serialize() {
        return null;
    }

    void deserialize(const(ubyte)[] message) {

    }
}