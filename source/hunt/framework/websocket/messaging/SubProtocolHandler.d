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

module hunt.framework.websocket.messaging.SubProtocolHandler;

// import hunt.http.codec.websocket.frame.WebSocketFrame;
// import hunt.http.codec.websocket.frame.Frame;
import hunt.framework.websocket.WebSocketSession;
import hunt.http.codec.websocket.model.CloseStatus;
import hunt.http.codec.websocket.stream.WebSocketConnection;

import hunt.stomp.Message;
import hunt.stomp.MessageChannel;

// alias WebSocketMessage = WebSocketFrame;
// alias WebSocketSession = WebSocketConnection;

/**
 * A contract for handling WebSocket messages as part of a higher level protocol,
 * referred to as "sub-protocol" in the WebSocket RFC specification.
 * Handles both {@link WebSocketMessage WebSocketMessages} from a client
 * as well as {@link Message Messages} to a client.
 *
 * <p>Implementations of this interface can be configured on a
 * {@link SubProtocolWebSocketHandler} which selects a sub-protocol handler to
 * delegate messages to based on the sub-protocol requested by the client through
 * the {@code Sec-WebSocket-Protocol} request header.
 *
 * @author Andy Wilkinson
 * @author Rossen Stoyanchev
 * @since 4.0
 */
interface SubProtocolHandler {

	/**
	 * Return the list of sub-protocols supported by this handler (never {@code null}).
	 */
	string[] getSupportedProtocols();

	/**
	 * Handle the given {@link WebSocketMessage} received from a client.
	 * @param session the client session
	 * @param message the client message
	 * @param outputChannel an output channel to send messages to
	 */
	void handleMessageFromClient(WebSocketSession session, WebSocketMessage message, MessageChannel outputChannel);

	/**
	 * Handle the given {@link Message} to the client associated with the given WebSocket session.
	 * @param session the client session
	 * @param message the client message
	 */
	void handleMessageToClient(WebSocketSession session, MessageBase message);

	/**
	 * Resolve the session id from the given message or return {@code null}.
	 * @param message the message to resolve the session id from
	 */
	
	string resolveSessionId(MessageBase message);

	/**
	 * Invoked after a {@link WebSocketSession} has started.
	 * @param session the client session
	 * @param outputChannel a channel
	 */
	void afterSessionStarted(WebSocketSession session, MessageChannel outputChannel);

	/**
	 * Invoked after a {@link WebSocketSession} has ended.
	 * @param session the client session
	 * @param closeStatus the reason why the session was closed
	 * @param outputChannel a channel
	 */
	void afterSessionEnded(WebSocketSession session, 
		CloseStatus closeStatus, MessageChannel outputChannel);

	
	int opCmp(SubProtocolHandler o);

}
