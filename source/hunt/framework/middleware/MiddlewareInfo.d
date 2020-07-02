module hunt.framework.middleware.MiddlewareInfo;


/**
 * 
 */
class MiddlewareInfo {
    // Middleware
    string fullName;

    // module
    string moduleName;

    // controller
    string controller;

    // action
    string action;

    this() {

    }

    this(string fullName, string action, string controller, string moduleName) {
        this.fullName = fullName;
        this.action = action;
        this.controller = controller;
        this.moduleName = moduleName;
    }

    
}
