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

module hunt.framework.websocket.WebSocketSession;

// import java.io.Closeable;
// import java.io.IOException;
// import java.net.InetSocketAddress;
// import java.net.URI;
// import hunt.security.Principal;
// import java.util.List;
// import java.util.Map;

// import hunt.framework.http.HttpHeaders;

import hunt.collection;
import hunt.util.Common;

import hunt.net.util.HttpURI;

import hunt.http.codec.websocket.frame.WebSocketFrame;
import hunt.http.codec.websocket.model.CloseStatus;

alias WebSocketMessage = WebSocketFrame;

/**
 * A WebSocket session abstraction. Allows sending messages over a WebSocket
 * connection and closing it.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
interface WebSocketSession : Closeable {

    /**
     * Return a unique session identifier.
     */
    string getId();

    /**
     * Return the URI used to open the WebSocket connection.
     */

    HttpURI getUri();

    /**
     * Return the headers used in the handshake request (never {@code null}).
     */
    // HttpHeaders getHandshakeHeaders();

    /**
     * Return the map with attributes associated with the WebSocket session.
     * <p>On the server side the map can be populated initially through a
     * {@link hunt.framework.websocket.server.HandshakeInterceptor
     * HandshakeInterceptor}. On the client side the map can be populated via
     * {@link hunt.framework.websocket.client.WebSocketClient
     * WebSocketClient} handshake methods.
     * @return a Map with the session attributes (never {@code null})
     */
    Map!(string, Object) getAttributes();

    /**
     * Return a {@link java.security.Principal} instance containing the name
     * of the authenticated user.
     * <p>If the user has not been authenticated, the method returns <code>null</code>.
     */

    // Principal getPrincipal();

    /**
     * Return the address on which the request was received.
     */

    // InetSocketAddress getLocalAddress();

    /**
     * Return the address of the remote client.
     */

    // InetSocketAddress getRemoteAddress();

    /**
     * Return the negotiated sub-protocol.
     * @return the protocol identifier, or {@code null} if no protocol
     * was specified or negotiated successfully
     */

    string getAcceptedProtocol();

    /**
     * Configure the maximum size for an incoming text message.
     */
    void setTextMessageSizeLimit(int messageSizeLimit);

    /**
     * Get the configured maximum size for an incoming text message.
     */
    int getTextMessageSizeLimit();

    /**
     * Configure the maximum size for an incoming binary message.
     */
    void setBinaryMessageSizeLimit(int messageSizeLimit);

    /**
     * Get the configured maximum size for an incoming binary message.
     */
    int getBinaryMessageSizeLimit();

    /**
     * Determine the negotiated extensions.
     * @return the list of extensions, or an empty list if no extension
     * was specified or negotiated successfully
     */
    // List!(WebSocketExtension) getExtensions();

    /**
     * Send a WebSocket message: either {@link TextMessage} or {@link BinaryMessage}.
     */
    void sendMessage(WebSocketMessage message);

    void sendTextMessage(string message);
    void sendBinaryMessage(byte[] message);

    /**
     * Return whether the connection is still open.
     */
    bool isOpen();

    /**
     * Close the WebSocket connection with status 1000, i.e. equivalent to:
     * <pre class="code">
     * session.close(CloseStatus.NORMAL);
     * </pre>
     */
    override
    void close();

    /**
     * Close the WebSocket connection with the given close status.
     */
    void close(CloseStatus status);

}
