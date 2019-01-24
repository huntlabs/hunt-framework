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

module hunt.framework.websocket.messaging.SubProtocolErrorHandler;

import hunt.stomp.Message;

/**
 * A contract for handling sub-protocol errors sent to clients.
 *
 * @author Rossen Stoyanchev
 * @since 4.2
 * @param <T> the message payload type
 */
interface SubProtocolErrorHandler(T) {

    /**
     * Handle errors thrown while processing client messages providing an
     * opportunity to prepare the error message or to prevent one from being sent.
     * <p>Note that the STOMP protocol requires a server to close the connection
     * after sending an ERROR frame. To prevent an ERROR frame from being sent,
     * a handler could return {@code null} and send a notification message
     * through the broker instead, e.g. via a user destination.
     * @param clientMessage the client message related to the error, possibly
     * {@code null} if error occurred while parsing a WebSocket message
     * @param ex the cause for the error, never {@code null}
     * @return the error message to send to the client, or {@code null} in which
     * case no message will be sent.
     */

    Message!(T) handleClientMessageProcessingError(Message!(T) clientMessage, Throwable ex);

    /**
     * Handle errors sent from the server side to clients, e.g. errors from the
     * {@link hunt.stomp.simp.stomp.StompBrokerRelayMessageHandler
     * "broke relay"} because connectivity failed or the external broker sent an
     * error message, etc.
     * @param errorMessage the error message, never {@code null}
     * @return the error message to send to the client, or {@code null} in which
     * case no message will be sent.
     */

    Message!(T) handleErrorMessageToClient(Message!(T) errorMessage);

}
