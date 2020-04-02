module hunt.framework.application.closer.RedisCloser;

import hunt.util.Common;
import hunt.redis;

class RedisCloser : Closeable {
    private Redis _redis;
    
    this(Redis redis) {
        _redis = redis;
    }

    void close()
    {
        _redis.close();
    }
}
