/*
 * Copyright 2002-2018 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module hunt.framework.websocket.messaging.SubProtocolWebSocketHandler;

import hunt.framework.websocket.messaging.SubProtocolHandler;
import hunt.framework.websocket.WebSocketSession;
import hunt.framework.context.Lifecycle;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageChannel;
import hunt.framework.messaging.MessagingException;
import hunt.framework.websocket.exception;
import hunt.framework.websocket.SubProtocolCapable;
import hunt.framework.websocket.WebSocketMessageHandler;

import hunt.http.codec.websocket.frame.Frame;
import hunt.http.codec.websocket.model.CloseStatus;
import hunt.http.codec.websocket.stream.WebSocketConnection;
import hunt.http.server.WebSocketHandler;
// import hunt.framework.websocket.WebSocketMessage;
// import hunt.framework.websocket.handler.ConcurrentWebSocketSessionDecorator;
// import hunt.framework.websocket.handler.SessionLimitExceededException;
// import hunt.framework.websocket.sockjs.transport.session.PollingSockJsSession;
// import hunt.framework.websocket.sockjs.transport.session.StreamingSockJsSession;

import hunt.container;
import hunt.datetime;
import hunt.lang.common;
import hunt.lang.exception;
import hunt.logging;

import std.array;
import std.conv;


/**
 * An implementation of {@link WebSocketHandler} that delegates incoming WebSocket
 * messages to a {@link SubProtocolHandler} along with a {@link MessageChannel} to which
 * the sub-protocol handler can send messages from WebSocket clients to the application.
 *
 * <p>Also an implementation of {@link MessageHandler} that finds the WebSocket session
 * associated with the {@link Message} and passes it, along with the message, to the
 * sub-protocol handler to send messages from the application back to the client.
 *
 * @author Rossen Stoyanchev
 * @author Juergen Hoeller
 * @author Andy Wilkinson
 * @author Artem Bilan
 * @since 4.0
 */
class SubProtocolWebSocketHandler : WebSocketMessageHandler, 
	SubProtocolCapable, MessageHandler, SmartLifecycle  {

	/** The default value for {@link #setTimeToFirstMessage(int) timeToFirstMessage}. */
	private enum int DEFAULT_TIME_TO_FIRST_MESSAGE = 60 * 1000;

	private MessageChannel clientInboundChannel;

	private SubscribableChannel clientOutboundChannel;

	private Map!(string, SubProtocolHandler) protocolHandlerLookup;

	private Set!(SubProtocolHandler) protocolHandlers;
	
	private SubProtocolHandler defaultProtocolHandler;

	private Map!(string, WebSocketSessionHolder) sessions;

	private int sendTimeLimit = 10 * 1000;

	private int sendBufferSizeLimit = 512 * 1024;

	private int timeToFirstMessage = DEFAULT_TIME_TO_FIRST_MESSAGE;

	private long lastSessionCheckTime;

	// private ReentrantLock sessionCheckLock = new ReentrantLock();

	// private Stats stats;

	private bool running = false;

	private Object lifecycleMonitor;


	/**
	 * Create a new {@code SubProtocolWebSocketHandler} for the given inbound and outbound channels.
	 * @param clientInboundChannel the inbound {@code MessageChannel}
	 * @param clientOutboundChannel the outbound {@code MessageChannel}
	 */
	this(MessageChannel clientInboundChannel, SubscribableChannel clientOutboundChannel) {
		assert(clientInboundChannel, "Inbound MessageChannel must not be null");
		assert(clientOutboundChannel, "Outbound MessageChannel must not be null");
		
		// TODO: Tasks pending completion -@zxp at 10/28/2018, 8:14:10 PM
		// 
		// protocolHandlerLookup = new TreeMap!(string, SubProtocolHandler)(string.CASE_INSENSITIVE_ORDER);
		protocolHandlerLookup = new TreeMap!(string, SubProtocolHandler)();
		protocolHandlers = new LinkedHashSet!(SubProtocolHandler)();
		// sessions = new ConcurrentHashMap!(string, WebSocketSessionHolder)();
		sessions = new HashMap!(string, WebSocketSessionHolder)();
		lastSessionCheckTime = DateTimeHelper.currentTimeMillis();
		// stats = new Stats();
		lifecycleMonitor = new Object();
		this.clientInboundChannel = clientInboundChannel;
		this.clientOutboundChannel = clientOutboundChannel;
	}


	/**
	 * Configure one or more handlers to use depending on the sub-protocol requested by
	 * the client in the WebSocket handshake request.
	 * @param protocolHandlers the sub-protocol handlers to use
	 */
	void setProtocolHandlers(List!(SubProtocolHandler) protocolHandlers) {
		this.protocolHandlerLookup.clear();
		this.protocolHandlers.clear();
		foreach (SubProtocolHandler handler ; protocolHandlers) {
			addProtocolHandler(handler);
		}
	}

	List!(SubProtocolHandler) getProtocolHandlers() {
		return new ArrayList!(SubProtocolHandler)(this.protocolHandlers);
	}

	/**
	 * Register a sub-protocol handler.
	 */
	void addProtocolHandler(SubProtocolHandler handler) {
		string[] protocols = handler.getSupportedProtocols();
		if (protocols.empty()) {
			version(HUNT_DEBUG) {
				errorf("No sub-protocols for " ~ handler.to!string());
			}
			return;
		}
		foreach (string protocol ; protocols) {
			SubProtocolHandler replaced = this.protocolHandlerLookup.put(protocol, handler);
			if (replaced !is null && replaced != handler) {
				throw new IllegalStateException("Cannot map " ~ handler.to!string() ~
						" to protocol '" ~ protocol ~ "': already mapped to " ~ 
						replaced.to!string() ~ ".");
			}
		}
		this.protocolHandlers.add(handler);
	}

	/**
	 * Return the sub-protocols keyed by protocol name.
	 */
	Map!(string, SubProtocolHandler) getProtocolHandlerMap() {
		return this.protocolHandlerLookup;
	}

	/**
	 * Set the {@link SubProtocolHandler} to use when the client did not request a
	 * sub-protocol.
	 * @param defaultProtocolHandler the default handler
	 */
	void setDefaultProtocolHandler(SubProtocolHandler defaultProtocolHandler) {
		this.defaultProtocolHandler = defaultProtocolHandler;
		if (this.protocolHandlerLookup.isEmpty()) {
			setProtocolHandlers(Collections.singletonList(defaultProtocolHandler));
		}
	}

	/**
	 * Return the default sub-protocol handler to use.
	 */
	
	SubProtocolHandler getDefaultProtocolHandler() {
		return this.defaultProtocolHandler;
	}

	/**
	 * Return all supported protocols.
	 */
	string[] getSubProtocols() {
		return this.protocolHandlerLookup.byKey.array;
	}

	/**
	 * Specify the send-time limit (milliseconds).
	 * @see ConcurrentWebSocketSessionDecorator
	 */
	void setSendTimeLimit(int sendTimeLimit) {
		this.sendTimeLimit = sendTimeLimit;
	}

	/**
	 * Return the send-time limit (milliseconds).
	 */
	int getSendTimeLimit() {
		return this.sendTimeLimit;
	}

	/**
	 * Specify the buffer-size limit (number of bytes).
	 * @see ConcurrentWebSocketSessionDecorator
	 */
	void setSendBufferSizeLimit(int sendBufferSizeLimit) {
		this.sendBufferSizeLimit = sendBufferSizeLimit;
	}

	/**
	 * Return the buffer-size limit (number of bytes).
	 */
	int getSendBufferSizeLimit() {
		return this.sendBufferSizeLimit;
	}

	/**
	 * Set the maximum time allowed in milliseconds after the WebSocket connection
	 * is established and before the first sub-protocol message is received.
	 * <p>This handler is for WebSocket connections that use a sub-protocol.
	 * Therefore, we expect the client to send at least one sub-protocol message
	 * in the beginning, or else we assume the connection isn't doing well, e.g.
	 * proxy issue, slow network, and can be closed.
	 * <p>By default this is set to {@code 60,000} (1 minute).
	 * @param timeToFirstMessage the maximum time allowed in milliseconds
	 * @since 5.1
	 * @see #checkSessions()
	 */
	void setTimeToFirstMessage(int timeToFirstMessage) {
		this.timeToFirstMessage = timeToFirstMessage;
	}

	/**
	 * Return the maximum time allowed after the WebSocket connection is
	 * established and before the first sub-protocol message.
	 * @since 5.1
	 */
	int getTimeToFirstMessage() {
		return this.timeToFirstMessage;
	}

	/**
	 * Return a string describing internal state and counters.
	 */
	string getStatsInfo() {
		// return this.stats.toString();
		return "todo...";
	}

	bool isAutoStartup() {
		return true;
	}

	int getPhase() {
		return int.max;
	}

	// override
	final void start() {
		assert(this.defaultProtocolHandler !is null || !this.protocolHandlers.isEmpty(), "No handlers");

		synchronized (this.lifecycleMonitor) {
			this.clientOutboundChannel.subscribe(this);
			this.running = true;
		}
	}

	// override
	final void stop() {
		synchronized (this.lifecycleMonitor) {
			this.running = false;
			this.clientOutboundChannel.unsubscribe(this);
		}

		// Proactively notify all active WebSocket sessions
		foreach (WebSocketSessionHolder holder ; this.sessions.byValue) {
			try {
				holder.getSession().close(); // CloseStatus.GOING_AWAY
			}
			catch (Throwable ex) {
				version(HUNT_DEBUG) {
					warningf("Failed to close '" ~ holder.getSession().to!string() ~ 
						"': " ~ ex.toString());
				}
			}
		}
	}

	// override
	final void stop(Runnable callback) {
		synchronized (this.lifecycleMonitor) {
			stop();
			callback.run();
		}
	}

	// override
	final bool isRunning() {
		return this.running;
	}


	// override
	void afterConnectionEstablished(WebSocketSession session) {
		// WebSocketHandlerDecorator could close the session
		if (!session.isOpen()) {
			return;
		}

		version(HUNT_DEBUG) trace("new WebSocketSession: ", session.getId());

		// this.stats.incrementSessionCount(session);
		session = decorateSession(session);
		this.sessions.put(session.getId(), new WebSocketSessionHolder(session));
		findProtocolHandler(session).afterSessionStarted(session, this.clientInboundChannel);
	}

	/**
	 * Handle an inbound message from a WebSocket client.
	 */
	// override
	void handleMessage(WebSocketSession session, WebSocketMessage message) {
		WebSocketSessionHolder holder = this.sessions.get(session.getId());
		if (holder !is null) {
			session = holder.getSession();
		}
		SubProtocolHandler protocolHandler = findProtocolHandler(session);
		protocolHandler.handleMessageFromClient(session, message, this.clientInboundChannel);
		if (holder !is null) {
			holder.setHasHandledMessages();
		}
		checkSessions();
	}

	/**
	 * Handle an outbound Spring Message to a WebSocket client.
	 */
	override
	void handleMessage(MessageBase message) {
		string sessionId = resolveSessionId(message);
		if (sessionId is null) {
			version(HUNT_DEBUG) {
				errorf("Could not find session id in " ~ message.to!string());
			}
			return;
		}

		WebSocketSessionHolder holder = this.sessions.get(sessionId);
		if (holder is null) {
			version(HUNT_DEBUG) {
				// The broker may not have removed the session yet
				trace("No session for " ~ (cast(Object)message).toString());
			}
			return;
		}

		WebSocketSession session = holder.getSession();
		try {
			findProtocolHandler(session).handleMessageToClient(session, message);
		}
		catch (SessionLimitExceededException ex) {
			try {
				version(HUNT_DEBUG) {
					tracef("Terminating '" ~ session.to!string() ~ "'", ex);
				}
				// this.stats.incrementLimitExceededCount();
				clearSession(session, ex.getStatus()); // clear first, session may be unresponsive
				session.close(); // ex.getStatus()
			}
			catch (Exception secondException) {
				tracef("Failure while closing session " ~ sessionId ~ ".", secondException);
			}
		}
		catch (Exception ex) {
			// Could be part of normal workflow (e.g. browser tab closed)
			version(HUNT_DEBUG) {
				error("Failed to send message to client in " ~ session.to!string()
					~ ": " ~ message.to!string() ~ "\n");
				error(ex.msg);
			}
		}
	}

	// override
	void handleTransportError(WebSocketSession session, Throwable exception) {
		implementationMissing(false);
		// this.stats.incrementTransportError();
	}

	// override
	void afterConnectionClosed(WebSocketSession session, CloseStatus closeStatus) {
		clearSession(session, closeStatus);
	}

	// override
	bool supportsPartialMessages() {
		return false;
	}


	/**
	 * Decorate the given {@link WebSocketSession}, if desired.
	 * <p>The default implementation builds a {@link ConcurrentWebSocketSessionDecorator}
	 * with the configured {@link #getSendTimeLimit() send-time limit} and
	 * {@link #getSendBufferSizeLimit() buffer-size limit}.
	 * @param session the original {@code WebSocketSession}
	 * @return the decorated {@code WebSocketSession}, or potentially the given session as-is
	 * @since 4.3.13
	 */
	protected WebSocketSession decorateSession(WebSocketSession session) {
		// return new ConcurrentWebSocketSessionDecorator(session, getSendTimeLimit(), getSendBufferSizeLimit());
		return session;
	}

	/**
	 * Find a {@link SubProtocolHandler} for the given session.
	 * @param session the {@code WebSocketSession} to find a handler for
	 */
	protected final SubProtocolHandler findProtocolHandler(WebSocketSession session) {
		string protocol = null;
		try {
			protocol = session.getAcceptedProtocol();
		}
		catch (Exception ex) {
			// Shouldn't happen
			errorf("Failed to obtain session.getAcceptedProtocol(): " ~
					"will use the default protocol handler (if configured).\n", ex);
		}

		SubProtocolHandler handler;
		if (protocol.empty) {
			if (this.defaultProtocolHandler !is null) {
				handler = this.defaultProtocolHandler;
			}
			else if (this.protocolHandlers.size() == 1) {
				handler = this.protocolHandlers.iterator.front() ;
			}
			else {
				throw new IllegalStateException("Multiple protocol handlers configured and " ~
						"no protocol was negotiated. Consider configuring a default SubProtocolHandler.");
			}
		} else {
			handler = this.protocolHandlerLookup.get(protocol);
			if (handler is null) {
				throw new IllegalStateException(
						"No handler for '" ~ protocol ~ "' among " ~ this.protocolHandlerLookup.toString());
			}
		}
		return handler;
	}

	
	private string resolveSessionId(MessageBase message) {
		foreach (SubProtocolHandler handler ; this.protocolHandlerLookup.byValue) {
			string sessionId = handler.resolveSessionId(message);
			if (sessionId !is null) {
				return sessionId;
			}
		}
		if (this.defaultProtocolHandler !is null) {
			string sessionId = this.defaultProtocolHandler.resolveSessionId(message);
			if (sessionId !is null) {
				return sessionId;
			}
		}
		return null;
	}

	/**
	 * When a session is connected through a higher-level protocol it has a chance
	 * to use heartbeat management to shut down sessions that are too slow to send
	 * or receive messages. However, after a WebSocketSession is established and
	 * before the higher level protocol is fully connected there is a possibility for
	 * sessions to hang. This method checks and closes any sessions that have been
	 * connected for more than 60 seconds without having received a single message.
	 */
	private void checkSessions() {
		long currentTime = DateTimeHelper.currentTimeMillis();
		if (!isRunning() || (currentTime - this.lastSessionCheckTime < getTimeToFirstMessage())) {
			return;
		}

		// if (this.sessionCheckLock.tryLock()) {
			try {
				foreach (WebSocketSessionHolder holder ; this.sessions.byValue) {
					if (holder.hasHandledMessages()) {
						continue;
					}
					long timeSinceCreated = currentTime - holder.getCreateTime();
					if (timeSinceCreated < getTimeToFirstMessage()) {
						continue;
					}
					WebSocketSession session = holder.getSession();
					version(HUNT_DEBUG) {
						info("No messages received after " ~ timeSinceCreated.to!string() ~ " ms. " ~
								"Closing " ~ holder.getSession().to!string() ~ ".");
					}
					try {
						// this.stats.incrementNoMessagesReceivedCount();
						session.close(); // CloseStatus.SESSION_NOT_RELIABLE
					}
					catch (Throwable ex) {
						version(HUNT_DEBUG) {
							warningf("Failed to close unreliable " ~ session.to!string(), ex);
						}
					}
				}
			}
			finally {
				this.lastSessionCheckTime = currentTime;
				// this.sessionCheckLock.unlock();
			}
		// }
	}

	private void clearSession(WebSocketSession session, CloseStatus closeStatus) {
		version(HUNT_DEBUG) {
			trace("Clearing session " ~ session.getId());
		}
		if (this.sessions.remove(session.getId()) !is null) {
			// this.stats.decrementSessionCount(session);
		}
		findProtocolHandler(session).afterSessionEnded(session, closeStatus, this.clientInboundChannel);
	}

	// override void onConnect(WebSocketConnection webSocketConnection) {
	// 	afterConnectionEstablished(webSocketConnection);
	// 	// if(_connectHandler !is null) 
	// 	//     _connectHandler(webSocketConnection);
	// }

	// override void onFrame(Frame frame, WebSocketConnection connection) {
	// 	handleMessage(connection, cast(WebSocketMessage)frame);
	// }

	// override void onError(Exception t, WebSocketConnection connection) {
	// }

	override int opCmp(MessageHandler o) {
		implementationMissing(false);
		return 0;
	}


	override
	string toString() {
		return "SubProtocolWebSocketHandler" ~ this.protocolHandlers.toString();
	}


	// private class Stats {

	// 	private final AtomicInteger total = new AtomicInteger();

	// 	private final AtomicInteger webSocket = new AtomicInteger();

	// 	private final AtomicInteger httpStreaming = new AtomicInteger();

	// 	private final AtomicInteger httpPolling = new AtomicInteger();

	// 	private final AtomicInteger limitExceeded = new AtomicInteger();

	// 	private final AtomicInteger noMessagesReceived = new AtomicInteger();

	// 	private final AtomicInteger transportError = new AtomicInteger();

	// 	void incrementSessionCount(WebSocketSession session) {
	// 		getCountFor(session).incrementAndGet();
	// 		this.total.incrementAndGet();
	// 	}

	// 	void decrementSessionCount(WebSocketSession session) {
	// 		getCountFor(session).decrementAndGet();
	// 	}

	// 	void incrementLimitExceededCount() {
	// 		this.limitExceeded.incrementAndGet();
	// 	}

	// 	void incrementNoMessagesReceivedCount() {
	// 		this.noMessagesReceived.incrementAndGet();
	// 	}

	// 	void incrementTransportError() {
	// 		this.transportError.incrementAndGet();
	// 	}

	// 	private AtomicInteger getCountFor(WebSocketSession session) {
	// 		if (session instanceof PollingSockJsSession) {
	// 			return this.httpPolling;
	// 		}
	// 		else if (session instanceof StreamingSockJsSession) {
	// 			return this.httpStreaming;
	// 		}
	// 		else {
	// 			return this.webSocket;
	// 		}
	// 	}

	// 	string toString() {
	// 		return SubProtocolWebSocketHandler.this.sessions.size() ~
	// 				" current WS(" ~ this.webSocket.get() ~
	// 				")-HttpStream(" ~ this.httpStreaming.get() ~
	// 				")-HttpPoll(" ~ this.httpPolling.get() ~ "), " ~
	// 				this.total.get() ~ " total, " ~
	// 				(this.limitExceeded.get() ~ this.noMessagesReceived.get()) ~ " closed abnormally (" ~
	// 				this.noMessagesReceived.get() ~ " connect failure, " ~
	// 				this.limitExceeded.get() ~ " send limit, " ~
	// 				this.transportError.get() ~ " transport error)";
	// 	}
	// }

}



private class WebSocketSessionHolder {

	private WebSocketSession session;

	private long createTime;

	private bool _hasHandledMessages;

	this(WebSocketSession session) {
		this.session = session;
		this.createTime = DateTimeHelper.currentTimeMillis();
	}

	WebSocketSession getSession() {
		return this.session;
	}

	long getCreateTime() {
		return this.createTime;
	}

	void setHasHandledMessages() {
		this._hasHandledMessages = true;
	}

	bool hasHandledMessages() {
		return this._hasHandledMessages;
	}

	override
	string toString() {
		return "WebSocketSessionHolder[session=" ~ this.session.to!string() ~ ", createTime=" ~
				this.createTime.to!string() ~ ", hasHandledMessages=" ~ 
				this._hasHandledMessages.to!string() ~ "]";
	}
}