module hunt.framework.application.closer.EntityCloser;

import hunt.util.Common;
import hunt.entity.EntityManager;

class EntityCloser : Closeable {
    private EntityManager _obj;

    this(EntityManager entity) {
        _obj = entity;
    }

    void close() {
        _obj.close();
    }
}
