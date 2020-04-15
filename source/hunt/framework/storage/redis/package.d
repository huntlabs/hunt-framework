module hunt.framework.storage.redis;

import hunt.redis;
import hunt.framework.Simplify;
import hunt.logging;

import hunt.framework.application.closer;
import hunt.framework.provider.ServiceProvider;

Redis getRedis() {
    RedisPool pool = serviceContainer.resolve!RedisPool();
    Redis r = pool.getResource();
    resouceManager.push(new RedisCloser(r));
    return r;
}
