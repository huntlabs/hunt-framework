module hunt.framework.middleware.Middleware;


/**
 * Accepted middleware
 */
struct Middleware {
    string[] names;

    /**
     * The names must be fully qualified.
     */
    this(string[] names...) {
        this.names = names;
    }
}


/**
 * Skipped middleware
 */
struct WithoutMiddleware {
    string[] names;

    /**
     * The names must be fully qualified.
     */
    this(string[] names...) {
        this.names = names;
    }
}
