module hunt.framework.websocket.WebSocketController;

import hunt.lang.common;
import hunt.logging;
import hunt.framework.messaging.simp.annotation.SimpAnnotationMethodMessageHandler;
import hunt.framework.messaging.annotation;
import hunt.framework.messaging.Message;

import std.algorithm;
import std.array;
import std.conv;
import std.format;
import std.json;
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
mixin template ControllerExtensions(string moduleName = __MODULE__) {
    import hunt.framework.messaging.Message;
    import hunt.framework.messaging.converter.AbstractMessageConverter;
    import hunt.framework.messaging.converter.MessageConverter;
    import hunt.framework.messaging.converter.MessageConverterHelper;
    import hunt.http.codec.http.model.MimeTypes;
    import hunt.lang.Nullable;
    import hunt.logging;
    import hunt.util.JsonHelper;
    import hunt.util.serialize;
    import std.json;

    alias This = typeof(this);
    
    shared static this() {
        WebSocketControllerHelper.registerController!This();
    }

    
    override protected void __invoke(string methodName, MessageBase message, ReturnHandler handler ) {

        version(HUNT_DEBUG) infof("invoking %s ...", methodName);
        
        MessageConverter messageConverter = 
            annotationHandler.getMessageConverter();

        // MimeType mt = messageConverter.getMimeType();
        // info(mt.toString());
            
        Object ob = messageConverter.fromMessage(message, typeid(JSONValue));
        if(ob is null)
            warning("no payload");
        else {
             version(HUNT_DEBUG) infof("playload: %s", typeid(ob));
        }

        enum str = WebSocketControllerHelper.generateMethodSwitch!(This, moduleName);
        pragma(msg, str);
        mixin(str);

        version(HUNT_DEBUG) infof("invoking %s done", methodName);
    }
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
                pragma(msg, "skipping type defination: " ~ memberName);
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


    static string generateMethodSwitch(T, string moduleName)() {
        string c;
        c ~= "string currentParameterInfo;\n"; // for debug
        c ~= `
        switch(methodName) {`;

        foreach (memberName; __traits(derivedMembers, T)) {
                pragma(msg, "member-caller: " ~ memberName);

                static if (isType!(__traits(getMember, T, memberName))) {
                    pragma(msg, "skipping type defination: " ~ memberName);
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
                            foreach (t; __traits(getOverloads, T, memberName)) {
                                enum hasMessageMapping = hasUDA!(t, MessageMapping);                        
                                static if (hasMessageMapping) {

        enum identifiers = ParameterIdentifierTuple!t;
                                    c ~= generateMethodSwitchCases!(t, moduleName, memberName);
                                }
                            }
                        }
                    }
                }
            }                
                

            c ~= `default : {
                    version(HUNT_DEBUG) warning("do nothing for invoking " ~ methodName);
                }
            }`;
        
        return c;
    }

    private static string wrapperParameters(T, string methodName)() {
        string s;
        s ~= ``;

        return s;

    }

    private static string generateMethodSwitchCases(alias symbol, string moduleName, string methodName)() {
        string s;
        enum parametersInJson = "parametersInJson";

        s ~= `
                case "` ~ methodName ~ `" : {
                    auto temp = cast(Nullable!JSONValue) ob;
                    if(temp is null) {
                        warningf("Wrong pyaload type: %s, handler: %s", typeid(ob), "` ~ methodName ~ `");
                        return;
                    }

                    JSONValue ` ~ parametersInJson ~` = temp.value;
                    version(HUNT_DEBUG) tracef("incoming message");
            `; 

        enum argumentsNumber = arity!symbol;
        enum identifiers = ParameterIdentifierTuple!symbol;
        alias parameterTypes = Parameters!symbol;
        alias returnType = ReturnType!symbol;

        static if(argumentsNumber == 0) {
            static if(is(returnType == void)) {
                s ~= "         " ~ methodName ~ "();";
            } else {
                s ~= "         auto r = " ~ methodName ~ "();";
            }
        } else static if(argumentsNumber == 1) {
            alias parameterType = parameterTypes[0];
            static if(is(parameterType == JSONValue)) {
                enum varName = parametersInJson;
            } else {
                enum pt = parameterType.stringof;
                enum varName = "parameterModel";
                static if(is(parameterType == class) || is(parameterType == struct)) {
                    s ~= format(`        %1$s %2$s = JsonHelper.getAs!(%1$s)(%3$s);` ~ "\n",
                            pt, varName, parametersInJson);
                } else {
                    enum pn = identifiers[0];
                    s ~= format(`        %1$s %2$s = JsonHelper.getItemAs!(%1$s)(%3$s, "%4$s");` ~ "\n",
                            pt, varName, parametersInJson, pn);
                }                
            }

            static if(is(returnType == void)) {
                s ~= "                  " ~ methodName ~ "(" ~ varName ~ ");";
            } else {
                s ~= "                    auto r = " ~ methodName ~ "(" ~ varName ~ ");";
            }

        } else {
            string invokingStatement;
            invokingStatement ~= methodName ~"(";
            s ~= "        JSONValue item;\n";
            string pt;
            string tempVarName;

            static foreach(int i, string pn; identifiers) {
                pt = parameterTypes[i].stringof;
                tempVarName = "__var" ~ i.to!string();
                s ~= "currentParameterInfo =\"type: " ~ pt ~ ", name: " ~ pn ~ "\";\n"; // for debug

                static if(is(parameterTypes[i] == class) || is(parameterTypes[i] == struct)) {
                    if(pn == "__body" && (pt == "JSONValue" || pt == "const(JSONValue)") ) {
                        tempVarName = parametersInJson;
                    } 
                } 
                
                if(tempVarName != parametersInJson) {
                    // s ~= `           item = parametersInJson["` ~ pn ~ `"];` ~ "\n";
                    s ~= format(`           %1$s %2$s = JsonHelper.getItemAs!(%1$s)(%3$s, "%4$s");` ~ "\n\n",
                            pt, tempVarName, parametersInJson, pn);
                }

                static if(i == 0) {
                    invokingStatement ~= tempVarName;
                } else {
                    invokingStatement ~= ", " ~ tempVarName;
                }
            }
            
            invokingStatement ~= ");";

            static if(is(returnType == void)) {
                s ~= invokingStatement;
            } else {
                s ~= "           auto r = " ~ invokingStatement;
            }
        }

        static if(!is(returnType == void)) {
            s ~=`
                    if(handler !is null) {
                        JSONValue resultInJson = toJson(r);
                        string resultInString = resultInJson.toString();
                        version(HUNT_DEBUG) tracef("outgoing message: %s", resultInString);
                        handler(new Nullable!string(resultInString), typeid(string));  
                    }`;     
        }

        s ~= `
                    break;
                }
                
                `;   
        
        return s;

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
