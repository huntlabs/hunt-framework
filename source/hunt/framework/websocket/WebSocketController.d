module hunt.framework.websocket.WebSocketController;

import hunt.lang.common;
import hunt.logging;
import hunt.framework.messaging.simp.annotation.SimpAnnotationMethodMessageHandler;
import hunt.framework.messaging.annotation;
import hunt.framework.messaging.Message;

import std.algorithm;
import std.array;
// import std.container.array;
import std.traits;

alias ReturnHandler = void delegate(Object, TypeInfo);
alias MessageReturnHandler = void delegate(Object, TypeInfo, string[] receivers);


/**
*/
abstract class WebSocketController {

    this() {
        initialization();
    }

    final SimpAnnotationMethodMessageHandler annotationHandler() {
        return WebSocketControllerHelper.annotationMethodMessageHandler;
    }

    protected void initialization() {

    }

    protected void __invoke(string methodName, MessageBase message, ReturnHandler handler );
}

/**
*/
class WebSocketControllerHelper {

    __gshared WebSocketControllerProxy[string] controllers;
    __gshared SimpAnnotationMethodMessageHandler annotationMethodMessageHandler;
    __gshared MessageMappingInfo[] messageMappings;

    shared static this() {
    }

    static void invoke(string mappingName, MessageBase message, MessageReturnHandler handler ) {
        auto r = messageMappings.filter!(m => m.name == mappingName);
        size_t count = r.count();
        if(count == 0) {
            warningf("No mapping found: %s", mappingName);
        // } else if(count > 1) {
            // MessageMappingInfo m = r.front;
        } else {
            MessageMappingInfo m = r.front;
            WebSocketController c = controllers[m.controller].controller;
            c.__invoke(m.method, message, 
                (Object r, TypeInfo t) {  
                    if(handler !is null) handler(r, t, m.receivers); 
                }
            );
        }
    }

    // WebSocketController getController(string lookupDestination) {

    // }


    static void registerController(T)() if(is(T : WebSocketController)) {
        WebSocketController builder() {
            T c = new T();
            return c;
        }
        // t.annotationHandler = handler;
        enum fullName = fullyQualifiedName!(T);

        // auto itemPtr = fullName in controllers;
        // if(itemPtr !is null) {
        //     warning("message mapping collision: " ~ name);
        // }

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
                } else {
                    import std.meta : Alias;

                    alias currentMember = Alias!(__traits(getMember, T, memberName));
                    alias memberType = typeof(currentMember);
                    static if (is(memberType == function)) {
                        enum hasMessageMapping = hasUDA!(currentMember, MessageMapping);
                        enum hasSendTo = hasUDA!(currentMember, SendTo);
                        static if (hasMessageMapping) {
                            string[] receivers;
                            static if(hasSendTo) {
                                receivers = getUDAs!(currentMember, SendTo)[0].values;
                            }

                            foreach (string name; getUDAs!(currentMember, MessageMapping)[0].values) {
                                addMessageMapping(name, fullName, memberName, receivers);
                            }

                            // invoke("/hello", null, null); // for test
                        }
                    }
                }
            }
        }

    }

    static void addMessageMapping(string name, string controller, 
        string method, string[] receivers) {

        MessageMappingInfo info = new MessageMappingInfo(name, controller, method, receivers);
        infof("adding: name=%s, controller=%s, method=%s, receivers=%s", 
            name, controller, method, receivers);

        auto r = messageMappings.filter!(m => m.name == name);
        if(r.count() > 0) {
            warning("message mapping collision: " ~ name);
        }

        messageMappings ~= info;
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
    string[] receivers;

    this(string name, string controller, string method, string[] receivers) {
        this.name = name;
        this.controller = controller;
        this.method = method;
        this.receivers = receivers;
    }
}
