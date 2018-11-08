module hunt.framework.websocket.WebSocketControllerHelper;

import hunt.framework.websocket.WebSocketController;
import hunt.framework.messaging.simp.annotation.SimpAnnotationMethodMessageHandler;

class WebSocketControllerHelper {
    static WebSocketController[string] controllers;

    static void createControllers(SimpAnnotationMethodMessageHandler handler) {

    }

    WebSocketController createController(T)(SimpAnnotationMethodMessageHandler handler) {
        T t = new T();
        t.annotationHandler = handler;

        return t;
    }


    static void registerController(T)(SimpAnnotationMethodMessageHandler handler) {
        T t = new T();
        t.annotationHandler = handler;

        controllers[T.stringof] = t;
        // return t;
    }
}