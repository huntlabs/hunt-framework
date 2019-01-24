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

module hunt.framework.websocket.WebSocketMessageHandler;


import hunt.http.codec.websocket.frame.WebSocketFrame;
// import hunt.http.codec.websocket.frame.Frame;
import hunt.http.codec.websocket.model.CloseStatus;
// import hunt.http.codec.websocket.stream.WebSocketConnection;
import hunt.framework.websocket.WebSocketSession;

alias WebSocketMessage = WebSocketFrame;
// alias WebSocketSession = WebSocketConnection;

/**
 * A handler for WebSocket messages and lifecycle events.
 *
 * <p>Implementations of this interface are encouraged to handle exceptions locally where
 * it makes sense or alternatively let the exception bubble up in which case by default
 * the exception is logged and the session closed with
 * {@link CloseStatus#SERVER_ERROR SERVER_ERROR(1011)}. The exception handling
 * strategy is provided by
 * {@link hunt.framework.websocket.handler.ExceptionWebSocketHandlerDecorator
 * ExceptionWebSocketHandlerDecorator} and it can be customized or replaced by decorating
 * the {@link WebSocketHandler} with a different decorator.
 *
 * @author Rossen Stoyanchev
 * @author Phillip Webb
 * @since 4.0
 */
interface WebSocketMessageHandler {

    /**
     * Invoked after WebSocket negotiation has succeeded and the WebSocket connection is
     * opened and ready for use.
     * @throws Exception this method can handle or propagate exceptions; see class-level
     * Javadoc for details.
     */
    void afterConnectionEstablished(WebSocketSession session);

    /**
     * Invoked when a new WebSocket message arrives.
     * @throws Exception this method can handle or propagate exceptions; see class-level
     * Javadoc for details.
     */
    void handleMessage(WebSocketSession session, WebSocketMessage message);

    /**
     * Handle an error from the underlying WebSocket message transport.
     * @throws Exception this method can handle or propagate exceptions; see class-level
     * Javadoc for details.
     */
    void handleTransportError(WebSocketSession session, Throwable exception);

    /**
     * Invoked after the WebSocket connection has been closed by either side, or after a
     * transport error has occurred. Although the session may technically still be open,
     * depending on the underlying implementation, sending messages at this point is
     * discouraged and most likely will not succeed.
     * @throws Exception this method can handle or propagate exceptions; see class-level
     * Javadoc for details.
     */
    void afterConnectionClosed(WebSocketSession session, CloseStatus closeStatus);

    /**
     * Whether the WebSocketHandler handles partial messages. If this flag is set to
     * {@code true} and the underlying WebSocket server supports partial messages,
     * then a large WebSocket message, or one of an unknown size may be split and
     * maybe received over multiple calls to
     * {@link #handleMessage(WebSocketSession, WebSocketMessage)}. The flag
     * {@link hunt.framework.websocket.WebSocketMessage#isLast()} indicates if
     * the message is partial and whether it is the last part.
     */
    bool supportsPartialMessages();

}
