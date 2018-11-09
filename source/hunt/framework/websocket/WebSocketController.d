module hunt.framework.websocket.WebSocketController;

import hunt.lang.common;
import hunt.logging;
import hunt.framework.messaging.simp.annotation.SimpAnnotationMethodMessageHandler;
import hunt.framework.messaging.annotation;

import std.container.array;
import std.array;
import std.traits;

class AnnotationMethodHandlerAdapter {
    SimpAnnotationMethodMessageHandler handler;

}

/**
*/
class WebSocketController {

    AnnotationMethodHandlerAdapter annotationHandler;

    this() {
        initialization();
    }

    void initialization() {

    }

}

/**
*/
class WebSocketControllerHelper {

    __gshared WebSocketControllerProxy[string] controllers;
    __gshared AnnotationMethodHandlerAdapter annotationMethodAdapter;
    __gshared Array!MessageMappingInfo messageMappings;

    shared static this() {
        annotationMethodAdapter = new AnnotationMethodHandlerAdapter();
    }

    // static void invoke(string methodName, MessageBase message, ReturnHandler handler ) {

    // }

    // WebSocketController getController(string lookupDestination) {

    // }

    static void createControllers(AnnotationMethodHandlerAdapter handler) {

    }

    // WebSocketController createController(T)(AnnotationMethodHandlerAdapter handler) {
    //     T t = new T();
    //     t.annotationHandler = handler;

    //     return t;
    // }

    static void registerController(T)() {
        WebSocketController builder() {
            T c = new T();
            return c;
        }
        // t.annotationHandler = handler;
        enum fullName = fullyQualifiedName!(T);

        controllers[fullName] = new WebSocketControllerProxy(&builder);

        // 
        foreach (memberName; __traits(derivedMembers, T)) {
            pragma(msg, "member: " ~ memberName);

            static if (isType!(__traits(getMember, T, memberName))) {
                pragma(msg, "skipping type: " ~ memberName);
            } else {
                enum memberProtection = __traits(getProtection, __traits(getMember, T, memberName));
                static if (memberProtection == "private"
                        || memberProtection == "protected" || memberProtection == "export") {
                    version (HUNT_DEBUG) pragma(msg, "skip private member: " ~ memberName);
                }
                else {
                    import std.meta : Alias;

                    alias currentMember = Alias!(__traits(getMember, T, memberName));
                    alias memberType = typeof(currentMember);
                    static if (is(memberType == function)) {
                        enum hasMessageMapping = hasUDA!(currentMember, MessageMapping);
                        enum hasSendTo = hasUDA!(currentMember, SendTo);
                        static if (hasMessageMapping) {
                            foreach (string name; getUDAs!(currentMember, MessageMapping)[0].values) {
                                addMessageMapping(name, fullName, memberName);
                            }
                        }
                    }
                }
            }
        }

    }

    private static void addMessageMapping(string name, string controller, string method) {

        MessageMappingInfo info = new MessageMappingInfo(name, controller, method);

        infof("adding: name=%s, controller=%s, method=%s", name, controller, method);

        messageMappings.insertBack(info);
    }
}

/**
*/
class WebSocketControllerProxy {

    private WebSocketController _controller;
    private Func!WebSocketController _builder;

    this(Func!WebSocketController handler) {
        _builder = handler;
    }

    WebSocketController controller() {
        if (_controller is null && _builder !is null) {
            _controller = _builder();
        }
        return _controller;
    }

}

class MessageMappingInfo {
    string name;
    string controller;
    string method;

    this(string name, string controller, string method) {
        this.name = name;
        this.controller = controller;
        this.method = method;
    }
}
