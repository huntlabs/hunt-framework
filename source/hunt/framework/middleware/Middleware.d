module hunt.framework.middleware.Middleware;


/**
 * 
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
 * 
 */
struct SkippedMiddleware {
    string[] names;

    /**
     * The names must be fully qualified.
     */
    this(string[] names...) {
        this.names = names;
    }
}
