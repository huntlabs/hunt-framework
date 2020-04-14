module hunt.framework.application.ResourceManager;

import hunt.util.Common;
import hunt.framework.Simplify;

class ResouceManager {

    private Closeable[] _closeableObjects;

    void push(Closeable obj) {
        if (!inWorkerThread())
            return;

        assert(obj !is null);
        _closeableObjects ~= obj;
    }

    void clean() {
        foreach (obj; _closeableObjects) {
            obj.close();
        }
    }
}
