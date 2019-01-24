/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.websocket.server.WebSocketHandlerDecorator;

import hunt.http.codec.websocket.model.CloseStatus;
// import hunt.http.server.WebSocketHandler;
import hunt.framework.websocket.WebSocketMessageHandler;
// import hunt.framework.websocket.WebSocketMessage;
// import hunt.framework.websocket.WebSocketSession;

/**
 * Wraps another {@link hunt.framework.websocket.WebSocketHandler}
 * instance and delegates to it.
 *
 * <p>Also provides a {@link #getDelegate()} method to return the decorated
 * handler as well as a {@link #getLastHandler()} method to go through all nested
 * delegates and return the "last" handler.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
// class WebSocketHandlerDecorator : WebSocketHandler {

//     private final WebSocketHandler delegate;


//     WebSocketHandlerDecorator(WebSocketHandler delegate) {
//         assert(delegate, "Delegate must not be null");
//         this.delegate = delegate;
//     }


//     WebSocketHandler getDelegate() {
//         return this.delegate;
//     }

//     WebSocketHandler getLastHandler() {
//         WebSocketHandler result = this.delegate;
//         while (result instanceof WebSocketHandlerDecorator) {
//             result = ((WebSocketHandlerDecorator) result).getDelegate();
//         }
//         return result;
//     }

//     static WebSocketHandler unwrap(WebSocketHandler handler) {
//         if (handler instanceof WebSocketHandlerDecorator) {
//             return ((WebSocketHandlerDecorator) handler).getLastHandler();
//         }
//         else {
//             return handler;
//         }
//     }

//     override
//     void afterConnectionEstablished(WebSocketSession session) throws Exception {
//         this.delegate.afterConnectionEstablished(session);
//     }

//     override
//     void handleMessage(WebSocketSession session, WebSocketMessage<?> message) throws Exception {
//         this.delegate.handleMessage(session, message);
//     }

//     override
//     void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
//         this.delegate.handleTransportError(session, exception);
//     }

//     override
//     void afterConnectionClosed(WebSocketSession session, CloseStatus closeStatus) throws Exception {
//         this.delegate.afterConnectionClosed(session, closeStatus);
//     }

//     override
//     boolsupportsPartialMessages() {
//         return this.delegate.supportsPartialMessages();
//     }

//     override
//     string toString() {
//         return TypeUtils.getSimpleName(typeid(this)) ~ " [delegate=" ~ this.delegate ~ "]";
//     }

// }



/**
 * A factory for applying decorators to a WebSocketHandler.
 *
 * <p>Decoration should be done through sub-classing
 * {@link hunt.framework.websocket.handler.WebSocketHandlerDecorator
 * WebSocketHandlerDecorator} to allow any code to traverse decorators and/or
 * unwrap the original handler when necessary .
 *
 * @author Rossen Stoyanchev
 * @since 4.1.2
 */
interface WebSocketHandlerDecoratorFactory {

    /**
     * Decorate the given WebSocketHandler.
     * @param handler the handler to be decorated.
     * @return the same handler or the handler wrapped with a sub-class of
     * {@code WebSocketHandlerDecorator}.
     */
    WebSocketMessageHandler decorate(WebSocketMessageHandler handler);

}
