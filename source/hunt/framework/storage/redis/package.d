module hunt.framework.storage.redis;

import redis;
import hunt.framework.Simplify;
import hunt.logging;

private Redis _redis;


Redis getRedis() {
    if (_redis is null) {
        version (HUNT_DEBUG) {
            tracef("Create a redis connection with %s:%d, password:%s", config()
                    .redis.host, config().redis.port, config().redis.password);
        }

        if (config().redis.enabled)
        {
            _redis = new Redis(config().redis.host, config().redis.port, config().redis.password);
        }
        else
        {
            warning("Please set config hunt.redis.enabled = true");
        }
    }

    return _redis;
}
