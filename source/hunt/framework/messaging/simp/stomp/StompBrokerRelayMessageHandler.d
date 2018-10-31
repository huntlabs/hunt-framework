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

module hunt.framework.messaging.simp.stomp.StompBrokerRelayMessageHandler;

// import hunt.security.Principal;
// import hunt.container;

// import hunt.framework.messaging.Message;
// import hunt.framework.messaging.MessageChannel;
// import hunt.framework.messaging.MessageDeliveryException;
// 
// import hunt.framework.messaging.MessageHeaders;
// 
// 
// import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
// import hunt.framework.messaging.simp.SimpMessageType;
// import hunt.framework.messaging.simp.broker.AbstractBrokerMessageHandler;
// import hunt.framework.messaging.support.MessageBuilder;
// import hunt.framework.messaging.support.MessageHeaderAccessor;
// 
// // import hunt.framework.messaging.tcp.FixedIntervalReconnectStrategy;
// // import hunt.framework.messaging.tcp.TcpConnection;
// // import hunt.framework.messaging.tcp.TcpConnectionHandler;
// // import hunt.framework.messaging.tcp.TcpOperations;
// // import hunt.framework.messaging.tcp.reactor.ReactorNettyCodec;
// // import hunt.framework.messaging.tcp.reactor.ReactorNettyTcpClient;

// // import hunt.framework.util.concurrent.ListenableFuture;
// // import hunt.framework.util.concurrent.ListenableFutureCallback;
// // import hunt.framework.util.concurrent.ListenableFutureTask;

// /**
//  * A {@link hunt.framework.messaging.MessageHandler} that handles messages by
//  * forwarding them to a STOMP broker.
//  *
//  * <p>For each new {@link SimpMessageType#CONNECT CONNECT} message, an independent TCP
//  * connection to the broker is opened and used exclusively for all messages from the
//  * client that originated the CONNECT message. Messages from the same client are
//  * identified through the session id message header. Reversely, when the STOMP broker
//  * sends messages back on the TCP connection, those messages are enriched with the
//  * session id of the client and sent back downstream through the {@link MessageChannel}
//  * provided to the constructor.
//  *
//  * <p>This class also automatically opens a default "system" TCP connection to the
//  * message broker that is used for sending messages that originate from the server
//  * application (as opposed to from a client). Such messages are not associated with
//  * any client and therefore do not have a session id header. The "system" connection
//  * is effectively shared and cannot be used to receive messages. Several properties
//  * are provided to configure the "system" connection including:
//  * <ul>
//  * <li>{@link #setSystemLogin}</li>
//  * <li>{@link #setSystemPasscode}</li>
//  * <li>{@link #setSystemHeartbeatSendInterval}</li>
//  * <li>{@link #setSystemHeartbeatReceiveInterval}</li>
//  * </ul>
//  *
//  * @author Rossen Stoyanchev
//  * @author Andy Wilkinson
//  * @since 4.0
//  */
class StompBrokerRelayMessageHandler  { // : AbstractBrokerMessageHandler

// 	/**
// 	 * The system session ID.
// 	 */
// 	enum string SYSTEM_SESSION_ID = "_system_";

// 	/** STOMP recommended error of margin for receiving heartbeats. */
// 	private enum long HEARTBEAT_MULTIPLIER = 3;

// 	/**
// 	 * Heartbeat starts once CONNECTED frame with heartbeat settings is received.
// 	 * If CONNECTED doesn't arrive within a minute, we'll close the connection.
// 	 */
// 	private enum int MAX_TIME_TO_CONNECTED_FRAME = 60 * 1000;

// 	private enum byte[] EMPTY_PAYLOAD = [];

// 	// private static final ListenableFutureTask!(Void) EMPTY_TASK = new ListenableFutureTask<>(new VoidCallable());

// 	private __gshared Message!(byte[]) HEARTBEAT_MESSAGE;


// 	shared static this() {
// 		// EMPTY_TASK.run();
// 		StompHeaderAccessor accessor = StompHeaderAccessor.createForHeartbeat();
// 		HEARTBEAT_MESSAGE = MessageHelper.createMessage(StompDecoder.HEARTBEAT_PAYLOAD, accessor.getMessageHeaders());
// 	}


// 	private string relayHost = "127.0.0.1";

// 	private int relayPort = 61613;

// 	private string clientLogin = "guest";

// 	private string clientPasscode = "guest";

// 	private string systemLogin = "guest";

// 	private string systemPasscode = "guest";

// 	private long systemHeartbeatSendInterval = 10000;

// 	private long systemHeartbeatReceiveInterval = 10000;

// 	private final Map!(string, MessageHandler) systemSubscriptions = new HashMap<>(4);

	
// 	private string virtualHost;

	
// 	private TcpOperations!(byte[]) tcpClient;

	
// 	private MessageHeaderInitializer headerInitializer;

// 	private final Stats stats = new Stats();

// 	private final Map!(string, StompConnectionHandler) connectionHandlers = new ConcurrentHashMap<>();


// 	/**
// 	 * Create a StompBrokerRelayMessageHandler instance with the given message channels
// 	 * and destination prefixes.
// 	 * @param inboundChannel the channel for receiving messages from clients (e.g. WebSocket clients)
// 	 * @param outboundChannel the channel for sending messages to clients (e.g. WebSocket clients)
// 	 * @param brokerChannel the channel for the application to send messages to the broker
// 	 * @param destinationPrefixes the broker supported destination prefixes; destinations
// 	 * that do not match the given prefix are ignored.
// 	 */
// 	StompBrokerRelayMessageHandler(SubscribableChannel inboundChannel, MessageChannel outboundChannel,
// 			SubscribableChannel brokerChannel, Collection!(string) destinationPrefixes) {

// 		super(inboundChannel, outboundChannel, brokerChannel, destinationPrefixes);
// 	}


// 	/**
// 	 * Set the STOMP message broker host.
// 	 */
// 	void setRelayHost(string relayHost) {
// 		Assert.hasText(relayHost, "relayHost must not be empty");
// 		this.relayHost = relayHost;
// 	}

// 	/**
// 	 * Return the STOMP message broker host.
// 	 */
// 	string getRelayHost() {
// 		return this.relayHost;
// 	}

// 	/**
// 	 * Set the STOMP message broker port.
// 	 */
// 	void setRelayPort(int relayPort) {
// 		this.relayPort = relayPort;
// 	}

// 	/**
// 	 * Return the STOMP message broker port.
// 	 */
// 	int getRelayPort() {
// 		return this.relayPort;
// 	}
// 	/**
// 	 * Set the login to use when creating connections to the STOMP broker on
// 	 * behalf of connected clients.
// 	 * <p>By default this is set to "guest".
// 	 * @see #setSystemLogin(string)
// 	 */
// 	void setClientLogin(string clientLogin) {
// 		Assert.hasText(clientLogin, "clientLogin must not be empty");
// 		this.clientLogin = clientLogin;
// 	}

// 	/**
// 	 * Return the configured login to use for connections to the STOMP broker
// 	 * on behalf of connected clients.
// 	 * @see #getSystemLogin()
// 	 */
// 	string getClientLogin() {
// 		return this.clientLogin;
// 	}

// 	/**
// 	 * Set the client passcode to use to create connections to the STOMP broker on
// 	 * behalf of connected clients.
// 	 * <p>By default this is set to "guest".
// 	 * @see #setSystemPasscode
// 	 */
// 	void setClientPasscode(string clientPasscode) {
// 		Assert.hasText(clientPasscode, "clientPasscode must not be empty");
// 		this.clientPasscode = clientPasscode;
// 	}

// 	/**
// 	 * Return the configured passcode to use for connections to the STOMP broker on
// 	 * behalf of connected clients.
// 	 * @see #getSystemPasscode()
// 	 */
// 	string getClientPasscode() {
// 		return this.clientPasscode;
// 	}

// 	/**
// 	 * Set the login for the shared "system" connection used to send messages to
// 	 * the STOMP broker from within the application, i.e. messages not associated
// 	 * with a specific client session (e.g. REST/HTTP request handling method).
// 	 * <p>By default this is set to "guest".
// 	 */
// 	void setSystemLogin(string systemLogin) {
// 		Assert.hasText(systemLogin, "systemLogin must not be empty");
// 		this.systemLogin = systemLogin;
// 	}

// 	/**
// 	 * Return the login used for the shared "system" connection to the STOMP broker.
// 	 */
// 	string getSystemLogin() {
// 		return this.systemLogin;
// 	}

// 	/**
// 	 * Set the passcode for the shared "system" connection used to send messages to
// 	 * the STOMP broker from within the application, i.e. messages not associated
// 	 * with a specific client session (e.g. REST/HTTP request handling method).
// 	 * <p>By default this is set to "guest".
// 	 */
// 	void setSystemPasscode(string systemPasscode) {
// 		this.systemPasscode = systemPasscode;
// 	}

// 	/**
// 	 * Return the passcode used for the shared "system" connection to the STOMP broker.
// 	 */
// 	string getSystemPasscode() {
// 		return this.systemPasscode;
// 	}


// 	/**
// 	 * Set the interval, in milliseconds, at which the "system" connection will, in the
// 	 * absence of any other data being sent, send a heartbeat to the STOMP broker. A value
// 	 * of zero will prevent heartbeats from being sent to the broker.
// 	 * <p>The default value is 10000.
// 	 * <p>See class-level documentation for more information on the "system" connection.
// 	 */
// 	void setSystemHeartbeatSendInterval(long systemHeartbeatSendInterval) {
// 		this.systemHeartbeatSendInterval = systemHeartbeatSendInterval;
// 	}

// 	/**
// 	 * Return the interval, in milliseconds, at which the "system" connection will
// 	 * send heartbeats to the STOMP broker.
// 	 */
// 	long getSystemHeartbeatSendInterval() {
// 		return this.systemHeartbeatSendInterval;
// 	}

// 	/**
// 	 * Set the maximum interval, in milliseconds, at which the "system" connection
// 	 * expects, in the absence of any other data, to receive a heartbeat from the STOMP
// 	 * broker. A value of zero will configure the connection to expect not to receive
// 	 * heartbeats from the broker.
// 	 * <p>The default value is 10000.
// 	 * <p>See class-level documentation for more information on the "system" connection.
// 	 */
// 	void setSystemHeartbeatReceiveInterval(long heartbeatReceiveInterval) {
// 		this.systemHeartbeatReceiveInterval = heartbeatReceiveInterval;
// 	}

// 	/**
// 	 * Return the interval, in milliseconds, at which the "system" connection expects
// 	 * to receive heartbeats from the STOMP broker.
// 	 */
// 	long getSystemHeartbeatReceiveInterval() {
// 		return this.systemHeartbeatReceiveInterval;
// 	}

// 	/**
// 	 * Configure one more destinations to subscribe to on the shared "system"
// 	 * connection along with MessageHandler's to handle received messages.
// 	 * <p>This is for internal use in a multi-application server scenario where
// 	 * servers forward messages to each other (e.g. unresolved user destinations).
// 	 * @param subscriptions the destinations to subscribe to.
// 	 */
// 	void setSystemSubscriptions(Map!(string, MessageHandler) subscriptions) {
// 		this.systemSubscriptions.clear();
// 		if (subscriptions !is null) {
// 			this.systemSubscriptions.putAll(subscriptions);
// 		}
// 	}

// 	/**
// 	 * Return the configured map with subscriptions on the "system" connection.
// 	 */
// 	Map!(string, MessageHandler) getSystemSubscriptions() {
// 		return this.systemSubscriptions;
// 	}

// 	/**
// 	 * Set the value of the "host" header to use in STOMP CONNECT frames. When this
// 	 * property is configured, a "host" header will be added to every STOMP frame sent to
// 	 * the STOMP broker. This may be useful for example in a cloud environment where the
// 	 * actual host to which the TCP connection is established is different from the host
// 	 * providing the cloud-based STOMP service.
// 	 * <p>By default this property is not set.
// 	 */
// 	void setVirtualHost(string virtualHost) {
// 		this.virtualHost = virtualHost;
// 	}

// 	/**
// 	 * Return the configured virtual host value.
// 	 */
	
// 	string getVirtualHost() {
// 		return this.virtualHost;
// 	}

// 	/**
// 	 * Configure a TCP client for managing TCP connections to the STOMP broker.
// 	 * <p>By default {@link ReactorNettyTcpClient} is used.
// 	 * <p><strong>Note:</strong> when this property is used, any
// 	 * {@link #setRelayHost(string) host} or {@link #setRelayPort(int) port}
// 	 * specified are effectively ignored.
// 	 */
// 	void setTcpClient(TcpOperations!(byte[]) tcpClient) {
// 		this.tcpClient = tcpClient;
// 	}

// 	/**
// 	 * Get the configured TCP client (never {@code null} unless not configured
// 	 * invoked and this method is invoked before the handler is started and
// 	 * hence a default implementation initialized).
// 	 */
	
// 	TcpOperations!(byte[]) getTcpClient() {
// 		return this.tcpClient;
// 	}

// 	/**
// 	 * Configure a {@link MessageHeaderInitializer} to apply to the headers of all
// 	 * messages created through the {@code StompBrokerRelayMessageHandler} that
// 	 * are sent to the client outbound message channel.
// 	 * <p>By default this property is not set.
// 	 */
// 	void setHeaderInitializer(MessageHeaderInitializer headerInitializer) {
// 		this.headerInitializer = headerInitializer;
// 	}

// 	/**
// 	 * Return the configured header initializer.
// 	 */
	
// 	MessageHeaderInitializer getHeaderInitializer() {
// 		return this.headerInitializer;
// 	}

// 	/**
// 	 * Return a string describing internal state and counters.
// 	 */
// 	string getStatsInfo() {
// 		return this.stats.toString();
// 	}

// 	/**
// 	 * Return the current count of TCP connection to the broker.
// 	 */
// 	int getConnectionCount() {
// 		return this.connectionHandlers.size();
// 	}


// 	override
// 	protected void startInternal() {
// 		if (this.tcpClient is null) {
// 			this.tcpClient = initTcpClient();
// 		}

// 		version(HUNT_DEBUG) {
// 			info("Starting \"system\" session, " ~ toString());
// 		}

// 		StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.CONNECT);
// 		accessor.setAcceptVersion("1.1,1.2");
// 		accessor.setLogin(this.systemLogin);
// 		accessor.setPasscode(this.systemPasscode);
// 		accessor.setHeartbeat(this.systemHeartbeatSendInterval, this.systemHeartbeatReceiveInterval);
// 		string virtualHost = getVirtualHost();
// 		if (virtualHost !is null) {
// 			accessor.setHost(virtualHost);
// 		}
// 		accessor.setSessionId(SYSTEM_SESSION_ID);
// 		version(HUNT_DEBUG) {
// 			trace("Forwarding " ~ accessor.getShortLogMessage(EMPTY_PAYLOAD));
// 		}

// 		SystemStompConnectionHandler handler = new SystemStompConnectionHandler(accessor);
// 		this.connectionHandlers.put(handler.getSessionId(), handler);

// 		this.stats.incrementConnectCount();
// 		this.tcpClient.connect(handler, new FixedIntervalReconnectStrategy(5000));
// 	}

// 	private ReactorNettyTcpClient!(byte[]) initTcpClient() {
// 		StompDecoder decoder = new StompDecoder();
// 		if (this.headerInitializer !is null) {
// 			decoder.setHeaderInitializer(this.headerInitializer);
// 		}
// 		ReactorNettyCodec!(byte[]) codec = new StompReactorNettyCodec(decoder);
// 		ReactorNettyTcpClient!(byte[]) client = new ReactorNettyTcpClient<>(this.relayHost, this.relayPort, codec);
// 		client.setLogger(SimpLogging.forLog(client.getLogger()));
// 		return client;
// 	}

// 	override
// 	protected void stopInternal() {
// 		publishBrokerUnavailableEvent();
// 		if (this.tcpClient !is null) {
// 			try {
// 				this.tcpClient.shutdown().get(5000, TimeUnit.MILLISECONDS);
// 			}
// 			catch (Throwable ex) {
// 				error("Error in shutdown of TCP client", ex);
// 			}
// 		}
// 	}

// 	override
// 	protected void handleMessageInternal(MessageBase message) {
// 		string sessionId = SimpMessageHeaderAccessor.getSessionId(message.getHeaders());

// 		if (!isBrokerAvailable()) {
// 			if (sessionId is null || SYSTEM_SESSION_ID.equals(sessionId)) {
// 				throw new MessageDeliveryException("Message broker not active. Consider subscribing to " ~
// 						"receive BrokerAvailabilityEvent's from an ApplicationListener Spring bean.");
// 			}
// 			StompConnectionHandler handler = this.connectionHandlers.get(sessionId);
// 			if (handler !is null) {
// 				handler.sendStompErrorFrameToClient("Broker not available.");
// 				handler.clearConnection();
// 			}
// 			else {
// 				StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.ERROR);
// 				if (getHeaderInitializer() !is null) {
// 					getHeaderInitializer().initHeaders(accessor);
// 				}
// 				accessor.setSessionId(sessionId);
// 				Principal user = SimpMessageHeaderAccessor.getUser(message.getHeaders());
// 				if (user !is null) {
// 					accessor.setUser(user);
// 				}
// 				accessor.setMessage("Broker not available.");
// 				MessageHeaders headers = accessor.getMessageHeaders();
// 				getClientOutboundChannel().send(MessageHelper.createMessage(EMPTY_PAYLOAD, headers));
// 			}
// 			return;
// 		}

// 		StompHeaderAccessor stompAccessor;
// 		StompCommand command;

// 		MessageHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, MessageHeaderAccessor.class);
// 		if (accessor is null) {
// 			throw new IllegalStateException(
// 					"No header accessor (not using the SimpMessagingTemplate?): " ~ message);
// 		}
// 		else if (accessor instanceof StompHeaderAccessor) {
// 			stompAccessor = (StompHeaderAccessor) accessor;
// 			command = stompAccessor.getCommand();
// 		}
// 		else if (accessor instanceof SimpMessageHeaderAccessor) {
// 			stompAccessor = StompHeaderAccessor.wrap(message);
// 			command = stompAccessor.getCommand();
// 			if (command is null) {
// 				command = stompAccessor.updateStompCommandAsClientMessage();
// 			}
// 		}
// 		else {
// 			throw new IllegalStateException(
// 					"Unexpected header accessor type " ~ accessor.getClass() ~ " in " ~ message);
// 		}

// 		if (sessionId is null) {
// 			if (!SimpMessageType.MESSAGE.equals(stompAccessor.getMessageType())) {
// 				version(HUNT_DEBUG) {
// 					error("Only STOMP SEND supported from within the server side. Ignoring " ~ message);
// 				}
// 				return;
// 			}
// 			sessionId = SYSTEM_SESSION_ID;
// 			stompAccessor.setSessionId(sessionId);
// 		}

// 		string destination = stompAccessor.getDestination();
// 		if (command !is null && command.requiresDestination() && !checkDestinationPrefix(destination)) {
// 			return;
// 		}

// 		if (StompCommand.CONNECT.equals(command)) {
// 			version(HUNT_DEBUG) {
// 				trace(stompAccessor.getShortLogMessage(EMPTY_PAYLOAD));
// 			}
// 			stompAccessor = (stompAccessor.isMutable() ? stompAccessor : StompHeaderAccessor.wrap(message));
// 			stompAccessor.setLogin(this.clientLogin);
// 			stompAccessor.setPasscode(this.clientPasscode);
// 			if (getVirtualHost() !is null) {
// 				stompAccessor.setHost(getVirtualHost());
// 			}
// 			StompConnectionHandler handler = new StompConnectionHandler(sessionId, stompAccessor);
// 			this.connectionHandlers.put(sessionId, handler);
// 			this.stats.incrementConnectCount();
// 			assert(this.tcpClient !is null, "No TCP client available");
// 			this.tcpClient.connect(handler);
// 		}
// 		else if (StompCommand.DISCONNECT.equals(command)) {
// 			StompConnectionHandler handler = this.connectionHandlers.get(sessionId);
// 			if (handler is null) {
// 				version(HUNT_DEBUG) {
// 					trace("Ignoring DISCONNECT in session " ~ sessionId ~ ". Connection already cleaned up.");
// 				}
// 				return;
// 			}
// 			this.stats.incrementDisconnectCount();
// 			handler.forward(message, stompAccessor);
// 		}
// 		else {
// 			StompConnectionHandler handler = this.connectionHandlers.get(sessionId);
// 			if (handler is null) {
// 				version(HUNT_DEBUG) {
// 					trace("No TCP connection for session " ~ sessionId ~ " in " ~ message);
// 				}
// 				return;
// 			}
// 			handler.forward(message, stompAccessor);
// 		}
// 	}

// 	override
// 	string toString() {
// 		return "StompBrokerRelay[" ~ getTcpClientInfo() ~ "]";
// 	}

// 	private string getTcpClientInfo() {
// 		return this.tcpClient !is null ? this.tcpClient.toString() : this.relayHost ~ ":" ~ this.relayPort;
// 	}


// 	private class StompConnectionHandler implements TcpConnectionHandler!(byte[]) {

// 		private final string sessionId;

// 		private bool isRemoteClientSession;

// 		private final StompHeaderAccessor connectHeaders;

// 		private final MessageChannel outboundChannel;

		
// 		private TcpConnection!(byte[]) tcpConnection;

// 		private bool isStompConnected;


// 		protected StompConnectionHandler(string sessionId, StompHeaderAccessor connectHeaders) {
// 			this(sessionId, connectHeaders, true);
// 		}

// 		private StompConnectionHandler(string sessionId, StompHeaderAccessor connectHeaders,  isClientSession) {
// 			assert(sessionId, "'sessionId' must not be null");
// 			assert(connectHeaders, "'connectHeaders' must not be null");
// 			this.sessionId = sessionId;
// 			this.connectHeaders = connectHeaders;
// 			this.isRemoteClientSession = isClientSession;
// 			this.outboundChannel = getClientOutboundChannelForSession(sessionId);
// 		}

// 		string getSessionId() {
// 			return this.sessionId;
// 		}

		
// 		protected TcpConnection!(byte[]) getTcpConnection() {
// 			return this.tcpConnection;
// 		}

// 		override
// 		void afterConnected(TcpConnection!(byte[]) connection) {
// 			version(HUNT_DEBUG) {
// 				trace("TCP connection opened in session=" ~ getSessionId());
// 			}
// 			this.tcpConnection = connection;
// 			connection.onReadInactivity(() -> {
// 				if (this.tcpConnection !is null && !this.isStompConnected) {
// 					handleTcpConnectionFailure("No CONNECTED frame received in " ~
// 							MAX_TIME_TO_CONNECTED_FRAME ~ " ms.", null);
// 				}
// 			}, MAX_TIME_TO_CONNECTED_FRAME);
// 			connection.send(MessageHelper.createMessage(EMPTY_PAYLOAD, this.connectHeaders.getMessageHeaders()));
// 		}

// 		override
// 		void afterConnectFailure(Throwable ex) {
// 			handleTcpConnectionFailure("Failed to connect: " ~ ex.getMessage(), ex);
// 		}

// 		/**
// 		 * Invoked when any TCP connectivity issue is detected, i.e. failure to establish
// 		 * the TCP connection, failure to send a message, missed heartbeat, etc.
// 		 */
// 		protected void handleTcpConnectionFailure(string error, Throwable ex) {
// 			version(HUNT_DEBUG) {
// 				info("TCP connection failure in session " ~ this.sessionId ~ ": " ~ error, ex);
// 			}
// 			try {
// 				sendStompErrorFrameToClient(error);
// 			}
// 			finally {
// 				try {
// 					clearConnection();
// 				}
// 				catch (Throwable ex2) {
// 					version(HUNT_DEBUG) {
// 						trace("Failure while clearing TCP connection state in session " ~ this.sessionId, ex2);
// 					}
// 				}
// 			}
// 		}

// 		private void sendStompErrorFrameToClient(string errorText) {
// 			if (this.isRemoteClientSession) {
// 				StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.ERROR);
// 				if (getHeaderInitializer() !is null) {
// 					getHeaderInitializer().initHeaders(accessor);
// 				}
// 				accessor.setSessionId(this.sessionId);
// 				Principal user = this.connectHeaders.getUser();
// 				if (user !is null) {
// 					accessor.setUser(user);
// 				}
// 				accessor.setMessage(errorText);
// 				accessor.setLeaveMutable(true);
// 				MessageBase errorMessage = MessageHelper.createMessage(EMPTY_PAYLOAD, accessor.getMessageHeaders());
// 				handleInboundMessage(errorMessage);
// 			}
// 		}

// 		protected void handleInboundMessage(MessageBase message) {
// 			if (this.isRemoteClientSession) {
// 				this.outboundChannel.send(message);
// 			}
// 		}

// 		override
// 		void handleMessage(Message!(byte[]) message) {
// 			StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
// 			assert(accessor !is null, "No StompHeaderAccessor");
// 			accessor.setSessionId(this.sessionId);
// 			Principal user = this.connectHeaders.getUser();
// 			if (user !is null) {
// 				accessor.setUser(user);
// 			}

// 			StompCommand command = accessor.getCommand();
// 			if (StompCommand.CONNECTED.equals(command)) {
// 				version(HUNT_DEBUG) {
// 					trace("Received " ~ accessor.getShortLogMessage(EMPTY_PAYLOAD));
// 				}
// 				afterStompConnected(accessor);
// 			}
// 			else if (logger.isErrorEnabled() && StompCommand.ERROR.equals(command)) {
// 				error("Received " ~ accessor.getShortLogMessage(message.getPayload()));
// 			}
// 			else version(HUNT_DEBUG) {
// 				trace("Received " ~ accessor.getDetailedLogMessage(message.getPayload()));
// 			}

// 			handleInboundMessage(message);
// 		}

// 		/**
// 		 * Invoked after the STOMP CONNECTED frame is received. At this point the
// 		 * connection is ready for sending STOMP messages to the broker.
// 		 */
// 		protected void afterStompConnected(StompHeaderAccessor connectedHeaders) {
// 			this.isStompConnected = true;
// 			stats.incrementConnectedCount();
// 			initHeartbeats(connectedHeaders);
// 		}

// 		private void initHeartbeats(StompHeaderAccessor connectedHeaders) {
// 			if (this.isRemoteClientSession) {
// 				return;
// 			}

// 			TcpConnection!(byte[]) con = this.tcpConnection;
// 			assert(con !is null, "No TcpConnection available");

// 			long clientSendInterval = this.connectHeaders.getHeartbeat()[0];
// 			long clientReceiveInterval = this.connectHeaders.getHeartbeat()[1];
// 			long serverSendInterval = connectedHeaders.getHeartbeat()[0];
// 			long serverReceiveInterval = connectedHeaders.getHeartbeat()[1];

// 			if (clientSendInterval > 0 && serverReceiveInterval > 0) {
// 				long interval = Math.max(clientSendInterval, serverReceiveInterval);
// 				con.onWriteInactivity(() ->
// 						con.send(HEARTBEAT_MESSAGE).addCallback(
// 								result -> {},
// 								ex -> handleTcpConnectionFailure(
// 										"Failed to forward heartbeat: " ~ ex.getMessage(), ex)), interval);
// 			}
// 			if (clientReceiveInterval > 0 && serverSendInterval > 0) {
// 				final long interval = Math.max(clientReceiveInterval, serverSendInterval) * HEARTBEAT_MULTIPLIER;
// 				con.onReadInactivity(
// 						() -> handleTcpConnectionFailure("No messages received in " ~ interval ~ " ms.", null), interval);
// 			}
// 		}

// 		override
// 		void handleFailure(Throwable ex) {
// 			if (this.tcpConnection !is null) {
// 				handleTcpConnectionFailure("Transport failure: " ~ ex.getMessage(), ex);
// 			}
// 			else version(HUNT_DEBUG) {
// 				error("Transport failure: " ~ ex);
// 			}
// 		}

// 		override
// 		void afterConnectionClosed() {
// 			if (this.tcpConnection is null) {
// 				return;
// 			}
// 			try {
// 				version(HUNT_DEBUG) {
// 					trace("TCP connection to broker closed in session " ~ this.sessionId);
// 				}
// 				sendStompErrorFrameToClient("Connection to broker closed.");
// 			}
// 			finally {
// 				try {
// 					// Prevent clearConnection() from trying to close
// 					this.tcpConnection = null;
// 					clearConnection();
// 				}
// 				catch (Throwable ex) {
// 					// Shouldn't happen with connection reset beforehand
// 				}
// 			}
// 		}

// 		/**
// 		 * Forward the given message to the STOMP broker.
// 		 * <p>The method checks whether we have an active TCP connection and have
// 		 * received the STOMP CONNECTED frame. For client messages this should be
// 		 * false only if we lose the TCP connection around the same time when a
// 		 * client message is being forwarded, so we simply log the ignored message
// 		 * at debug level. For messages from within the application being sent on
// 		 * the "system" connection an exception is raised so that components sending
// 		 * the message have a chance to handle it -- by default the broker message
// 		 * channel is synchronous.
// 		 * <p>Note that if messages arrive concurrently around the same time a TCP
// 		 * connection is lost, there is a brief period of time before the connection
// 		 * is reset when one or more messages may sneak through and an attempt made
// 		 * to forward them. Rather than synchronizing to guard against that, this
// 		 * method simply lets them try and fail. For client sessions that may
// 		 * result in an additional STOMP ERROR frame(s) being sent downstream but
// 		 * code handling that downstream should be idempotent in such cases.
// 		 * @param message the message to send (never {@code null})
// 		 * @return a future to wait for the result
// 		 */
		
// 		ListenableFuture!(Void) forward(final MessageBase message, final StompHeaderAccessor accessor) {
// 			TcpConnection!(byte[]) conn = this.tcpConnection;

// 			if (!this.isStompConnected || conn is null) {
// 				if (this.isRemoteClientSession) {
// 					version(HUNT_DEBUG) {
// 						trace("TCP connection closed already, ignoring " ~
// 								accessor.getShortLogMessage(message.getPayload()));
// 					}
// 					return EMPTY_TASK;
// 				}
// 				else {
// 					throw new IllegalStateException("Cannot forward messages " ~
// 							(conn !is null ? "before STOMP CONNECTED. " : "while inactive. ") +
// 							"Consider subscribing to receive BrokerAvailabilityEvent's from " ~
// 							"an ApplicationListener Spring bean. Dropped " ~
// 							accessor.getShortLogMessage(message.getPayload()));
// 				}
// 			}

// 			final MessageBase messageToSend = (accessor.isMutable() && accessor.isModified()) ?
// 					MessageHelper.createMessage(message.getPayload(), accessor.getMessageHeaders()) : message;

// 			StompCommand command = accessor.getCommand();
// 			if (logger.isDebugEnabled() && (StompCommand.SEND.equals(command) || StompCommand.SUBSCRIBE.equals(command) ||
// 					StompCommand.UNSUBSCRIBE.equals(command) || StompCommand.DISCONNECT.equals(command))) {
// 				trace("Forwarding " ~ accessor.getShortLogMessage(message.getPayload()));
// 			}
// 			else version(HUNT_DEBUG) {
// 				trace("Forwarding " ~ accessor.getDetailedLogMessage(message.getPayload()));
// 			}

// 			ListenableFuture!(Void) future = conn.send((Message!(byte[])) messageToSend);
// 			future.addCallback(new ListenableFutureCallback!(Void)() {
// 				override
// 				void onSuccess(Void result) {
// 					if (accessor.getCommand() == StompCommand.DISCONNECT) {
// 						afterDisconnectSent(accessor);
// 					}
// 				}
// 				override
// 				void onFailure(Throwable ex) {
// 					if (tcpConnection !is null) {
// 						handleTcpConnectionFailure("failed to forward " ~
// 								accessor.getShortLogMessage(message.getPayload()), ex);
// 					}
// 					else version(HUNT_DEBUG) {
// 						error("Failed to forward " ~ accessor.getShortLogMessage(message.getPayload()));
// 					}
// 				}
// 			});
// 			return future;
// 		}

// 		/**
// 		 * After a DISCONNECT there should be no more client frames so we can
// 		 * close the connection pro-actively. However, if the DISCONNECT has a
// 		 * receipt header we leave the connection open and expect the server will
// 		 * respond with a RECEIPT and then close the connection.
// 		 * @see <a href="http://stomp.github.io/stomp-specification-1.2.html#DISCONNECT">
// 		 *     STOMP Specification 1.2 DISCONNECT</a>
// 		 */
// 		private void afterDisconnectSent(StompHeaderAccessor accessor) {
// 			if (accessor.getReceipt() is null) {
// 				try {
// 					clearConnection();
// 				}
// 				catch (Throwable ex) {
// 					version(HUNT_DEBUG) {
// 						trace("Failure while clearing TCP connection state in session " ~ this.sessionId, ex);
// 					}
// 				}
// 			}
// 		}

// 		/**
// 		 * Clean up state associated with the connection and close it.
// 		 * Any exception arising from closing the connection are propagated.
// 		 */
// 		void clearConnection() {
// 			version(HUNT_DEBUG) {
// 				trace("Cleaning up connection state for session " ~ this.sessionId);
// 			}

// 			if (this.isRemoteClientSession) {
// 				StompBrokerRelayMessageHandler.this.connectionHandlers.remove(this.sessionId);
// 			}

// 			this.isStompConnected = false;

// 			TcpConnection!(byte[]) conn = this.tcpConnection;
// 			this.tcpConnection = null;
// 			if (conn !is null) {
// 				version(HUNT_DEBUG) {
// 					trace("Closing TCP connection in session " ~ this.sessionId);
// 				}
// 				conn.close();
// 			}
// 		}

// 		override
// 		string toString() {
// 			return "StompConnectionHandler[sessionId=" ~ this.sessionId ~ "]";
// 		}
// 	}


// 	private class SystemStompConnectionHandler extends StompConnectionHandler {

// 		SystemStompConnectionHandler(StompHeaderAccessor connectHeaders) {
// 			super(SYSTEM_SESSION_ID, connectHeaders, false);
// 		}

// 		override
// 		protected void afterStompConnected(StompHeaderAccessor connectedHeaders) {
// 			version(HUNT_DEBUG) {
// 				info("\"System\" session connected.");
// 			}
// 			super.afterStompConnected(connectedHeaders);
// 			publishBrokerAvailableEvent();
// 			sendSystemSubscriptions();
// 		}

// 		private void sendSystemSubscriptions() {
// 			int i = 0;
// 			for (string destination : getSystemSubscriptions().keySet()) {
// 				StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.SUBSCRIBE);
// 				accessor.setSubscriptionId(string.valueOf(i++));
// 				accessor.setDestination(destination);
// 				version(HUNT_DEBUG) {
// 					trace("Subscribing to " ~ destination ~ " on \"system\" connection.");
// 				}
// 				TcpConnection!(byte[]) conn = getTcpConnection();
// 				if (conn !is null) {
// 					MessageHeaders headers = accessor.getMessageHeaders();
// 					conn.send(MessageHelper.createMessage(EMPTY_PAYLOAD, headers)).addCallback(
// 							result -> {},
// 							ex -> {
// 								string error = "Failed to subscribe in \"system\" session.";
// 								handleTcpConnectionFailure(error, ex);
// 							});
// 				}
// 			}
// 		}

// 		override
// 		protected void handleInboundMessage(MessageBase message) {
// 			StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
// 			if (accessor !is null && StompCommand.MESSAGE.equals(accessor.getCommand())) {
// 				string destination = accessor.getDestination();
// 				if (destination is null) {
// 					version(HUNT_DEBUG) {
// 						trace("Got message on \"system\" connection, with no destination: " ~
// 								accessor.getDetailedLogMessage(message.getPayload()));
// 					}
// 					return;
// 				}
// 				if (!getSystemSubscriptions().containsKey(destination)) {
// 					version(HUNT_DEBUG) {
// 						trace("Got message on \"system\" connection with no handler: " ~
// 								accessor.getDetailedLogMessage(message.getPayload()));
// 					}
// 					return;
// 				}
// 				try {
// 					MessageHandler handler = getSystemSubscriptions().get(destination);
// 					handler.handleMessage(message);
// 				}
// 				catch (Throwable ex) {
// 					version(HUNT_DEBUG) {
// 						trace("Error while handling message on \"system\" connection.", ex);
// 					}
// 				}
// 			}
// 		}

// 		override
// 		protected void handleTcpConnectionFailure(string errorMessage, Throwable ex) {
// 			super.handleTcpConnectionFailure(errorMessage, ex);
// 			publishBrokerUnavailableEvent();
// 		}

// 		override
// 		void afterConnectionClosed() {
// 			super.afterConnectionClosed();
// 			publishBrokerUnavailableEvent();
// 		}

// 		override
// 		ListenableFuture!(Void) forward(MessageBase message, StompHeaderAccessor accessor) {
// 			try {
// 				ListenableFuture!(Void) future = super.forward(message, accessor);
// 				if (message.getHeaders().get(SimpMessageHeaderAccessor.IGNORE_ERROR) is null) {
// 					future.get();
// 				}
// 				return future;
// 			}
// 			catch (Throwable ex) {
// 				throw new MessageDeliveryException(message, ex);
// 			}
// 		}
// 	}


// 	private static class VoidCallable implements Callable!(Void) {

// 		override
// 		Void call() {
// 			return null;
// 		}
// 	}


// 	private class Stats {

// 		private final AtomicInteger connect = new AtomicInteger();

// 		private final AtomicInteger connected = new AtomicInteger();

// 		private final AtomicInteger disconnect = new AtomicInteger();

// 		void incrementConnectCount() {
// 			this.connect.incrementAndGet();
// 		}

// 		void incrementConnectedCount() {
// 			this.connected.incrementAndGet();
// 		}

// 		void incrementDisconnectCount() {
// 			this.disconnect.incrementAndGet();
// 		}

// 		string toString() {
// 			return (connectionHandlers.size() ~ " sessions, " ~ getTcpClientInfo() +
// 					(isBrokerAvailable() ? " (available)" : " (not available)") +
// 					", processed CONNECT(" ~ this.connect.get() ~ ")-CONNECTED(" ~
// 					this.connected.get() ~ ")-DISCONNECT(" ~ this.disconnect.get() ~ ")");
// 		}
// 	}

}
