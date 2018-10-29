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

module hunt.framework.websocket.messaging.StompSubProtocolHandler;

import hunt.framework.websocket.messaging.SubProtocolHandler;
import hunt.http.codec.websocket.stream.WebSocketConnection;
import hunt.http.codec.websocket.frame.WebSocketFrame;

import hunt.container;
import hunt.lang.exception;

import hunt.framework.context.ApplicationEvent;
import hunt.framework.context.ApplicationEventPublisher;
import hunt.framework.context.ApplicationEventPublisherAware;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageChannel;
import hunt.framework.messaging.simp.SimpAttributes;
import hunt.framework.messaging.simp.SimpAttributesContextHolder;
import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
import hunt.framework.messaging.simp.SimpMessageType;
import hunt.framework.messaging.simp.stomp.BufferingStompDecoder;
import hunt.framework.messaging.simp.stomp.StompCommand;
import hunt.framework.messaging.simp.stomp.StompDecoder;
import hunt.framework.messaging.simp.stomp.StompEncoder;
import hunt.framework.messaging.simp.stomp.StompHeaderAccessor;
import hunt.framework.messaging.support.AbstractMessageChannel;
import hunt.framework.messaging.support.ChannelInterceptor;
import hunt.framework.messaging.support.ImmutableMessageChannelInterceptor;
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;
import hunt.framework.messaging.support.MessageHeaderInitializer;

import hunt.framework.util.MimeTypeUtils;
import hunt.framework.websocket.BinaryMessage;
import hunt.http.codec.websocket.model.CloseStatus;
import hunt.framework.websocket.TextMessage;
import hunt.framework.websocket.WebSocketMessage;
import hunt.framework.websocket.WebSocketSession;
import hunt.framework.websocket.handler.SessionLimitExceededException;
import hunt.framework.websocket.handler.WebSocketSessionDecorator;
// import hunt.framework.websocket.sockjs.transport.SockJsSession;

/**
 * A {@link SubProtocolHandler} for STOMP that supports versions 1.0, 1.1, and 1.2
 * of the STOMP specification.
 *
 * @author Rossen Stoyanchev
 * @author Andy Wilkinson
 * @since 4.0
 */
class StompSubProtocolHandler : SubProtocolHandler { // , ApplicationEventPublisherAware

	/**
	 * This handler supports assembling large STOMP messages split into multiple
	 * WebSocket messages and STOMP clients (like stomp.js) indeed split large STOMP
	 * messages at 16K boundaries. Therefore the WebSocket server input message
	 * buffer size must allow 16K at least plus a little extra for SockJS framing.
	 */
	enum int MINIMUM_WEBSOCKET_MESSAGE_SIZE = 16 * 1024 + 256;

	/**
	 * The name of the header set on the CONNECTED frame indicating the name
	 * of the user authenticated on the WebSocket session.
	 */
	enum string CONNECTED_USER_HEADER = "user-name";

	private enum string[] SUPPORTED_VERSIONS = {"1.2", "1.1", "1.0"};

	private enum byte[] EMPTY_PAYLOAD = [];

	private StompSubProtocolErrorHandler errorHandler;

	private int messageSizeLimit = 64 * 1024;

	private StompEncoder stompEncoder;

	private StompDecoder stompDecoder;

	private Map!(string, BufferingStompDecoder) decoders;

	private MessageHeaderInitializer headerInitializer;

	private Map!(string, Principal) stompAuthentications;
	
	private bool immutableMessageInterceptorPresent;
	
	private ApplicationEventPublisher eventPublisher;

	// private Stats stats = new Stats();

	this() {
		stompEncoder = new StompEncoder();
		stompDecoder = new StompDecoder();
		decoders = new HashMap!(string, BufferingStompDecoder)();
		stompAuthentications = new HashMap!(string, Principal)();
	}


	/**
	 * Configure a handler for error messages sent to clients which allows
	 * customizing the error messages or preventing them from being sent.
	 * <p>By default this isn't configured in which case an ERROR frame is sent
	 * with a message header reflecting the error.
	 * @param errorHandler the error handler
	 */
	void setErrorHandler(StompSubProtocolErrorHandler errorHandler) {
		this.errorHandler = errorHandler;
	}

	/**
	 * Return the configured error handler.
	 */
	
	StompSubProtocolErrorHandler getErrorHandler() {
		return this.errorHandler;
	}

	/**
	 * Configure the maximum size allowed for an incoming STOMP message.
	 * Since a STOMP message can be received in multiple WebSocket messages,
	 * buffering may be required and therefore it is necessary to know the maximum
	 * allowed message size.
	 * <p>By default this property is set to 64K.
	 * @since 4.0.3
	 */
	void setMessageSizeLimit(int messageSizeLimit) {
		this.messageSizeLimit = messageSizeLimit;
	}

	/**
	 * Get the configured message buffer size limit in bytes.
	 * @since 4.0.3
	 */
	int getMessageSizeLimit() {
		return this.messageSizeLimit;
	}

	/**
	 * Configure a {@link StompEncoder} for encoding STOMP frames.
	 * @since 4.3.5
	 */
	void setEncoder(StompEncoder encoder) {
		this.stompEncoder = encoder;
	}

	/**
	 * Configure a {@link StompDecoder} for decoding STOMP frames.
	 * @since 4.3.5
	 */
	void setDecoder(StompDecoder decoder) {
		this.stompDecoder = decoder;
	}

	/**
	 * Configure a {@link MessageHeaderInitializer} to apply to the headers of all
	 * messages created from decoded STOMP frames and other messages sent to the
	 * client inbound channel.
	 * <p>By default this property is not set.
	 */
	void setHeaderInitializer(MessageHeaderInitializer headerInitializer) {
		this.headerInitializer = headerInitializer;
		this.stompDecoder.setHeaderInitializer(headerInitializer);
	}

	/**
	 * Return the configured header initializer.
	 */
	
	MessageHeaderInitializer getHeaderInitializer() {
		return this.headerInitializer;
	}

	override
	string[] getSupportedProtocols() {
		return ["v10.stomp", "v11.stomp", "v12.stomp"];
	}

	override
	void setApplicationEventPublisher(ApplicationEventPublisher applicationEventPublisher) {
		this.eventPublisher = applicationEventPublisher;
	}

	/**
	 * Return a string describing internal state and counters.
	 */
	string getStatsInfo() {
		implementationMissing(false);
		return "this.stats.toString()";
	}


	/**
	 * Handle incoming WebSocket messages from clients.
	 */
	void handleMessageFromClient(WebSocketSession session,
			WebSocketFrame webSocketMessage, MessageChannel outputChannel) {

		List!(Message!(byte[])) messages;
		try {
			ByteBuffer byteBuffer = webSocketMessage.getPayload();
			// if (webSocketMessage instanceof TextMessage) {
			// 	byteBuffer = ByteBuffer.wrap(((TextMessage) webSocketMessage).asBytes());
			// }
			// else if (webSocketMessage instanceof BinaryMessage) {
			// 	byteBuffer = ((BinaryMessage) webSocketMessage).getPayload();
			// }
			// else {
			// 	return;
			// }

			BufferingStompDecoder decoder = this.decoders.get(session.getId());
			if (decoder is null) {
				throw new IllegalStateException("No decoder for session id '" ~ session.getId() ~ "'");
			}

			messages = decoder.decode(byteBuffer);
			if (messages.isEmpty()) {
				version(HUNT_DEBUG) {
					trace("Incomplete STOMP frame content received in session " ~
							session.toString() ~ ", bufferSize=" ~ to!string(decoder.getBufferSize()) ~
							", bufferSizeLimit=" ~ to!string(decoder.getBufferSizeLimit()) ~ ".");
				}
				return;
			}
		}
		catch (Throwable ex) {
			version(HUNT_DEBUG) {
				errorf("Failed to parse " ~ webSocketMessage.toString() ~
						" in session " ~ session.getId() ~ ". Sending STOMP ERROR to client.\n", ex);
			}
			handleError(session, ex, null);
			return;
		}

		foreach (Message!(byte[]) message ; messages) {
			try {
				StompHeaderAccessor headerAccessor =
						MessageHeaderAccessor.getAccessor!(StompHeaderAccessor)(message);
				assert(headerAccessor !is null, "No StompHeaderAccessor");

				headerAccessor.setSessionId(session.getId());
				headerAccessor.setSessionAttributes(session.getAttributes());
				headerAccessor.setUser(getUser(session));
				headerAccessor.setHeader(SimpMessageHeaderAccessor.HEART_BEAT_HEADER, headerAccessor.getHeartbeat());
				if (!detectImmutableMessageInterceptor(outputChannel)) {
					headerAccessor.setImmutable();
				}

				version(HUNT_DEBUG) {
					trace("From client: " ~ headerAccessor.getShortLogMessage(message.getPayload()));
				}

				StompCommand command = headerAccessor.getCommand();
				boolisConnect = StompCommand.CONNECT.equals(command);
				if (isConnect) {
					this.stats.incrementConnectCount();
				}
				else if (StompCommand.DISCONNECT.equals(command)) {
					this.stats.incrementDisconnectCount();
				}

				try {
					SimpAttributesContextHolder.setAttributesFromMessage(message);
					boolsent = outputChannel.send(message);

					if (sent) {
						if (isConnect) {
							Principal user = headerAccessor.getUser();
							if (user !is null && user != session.getPrincipal()) {
								this.stompAuthentications.put(session.getId(), user);
							}
						}
						if (this.eventPublisher !is null) {
							Principal user = getUser(session);
							if (isConnect) {
								publishEvent(this.eventPublisher, new SessionConnectEvent(this, message, user));
							}
							else if (StompCommand.SUBSCRIBE.equals(command)) {
								publishEvent(this.eventPublisher, new SessionSubscribeEvent(this, message, user));
							}
							else if (StompCommand.UNSUBSCRIBE.equals(command)) {
								publishEvent(this.eventPublisher, new SessionUnsubscribeEvent(this, message, user));
							}
						}
					}
				}
				finally {
					SimpAttributesContextHolder.resetAttributes();
				}
			}
			catch (Throwable ex) {
				version(HUNT_DEBUG) {
					errorf("Failed to send client message to application via MessageChannel" ~
							" in session " ~ session.getId() ~ ". Sending STOMP ERROR to client.", ex);
				}
				handleError(session, ex, message);
			}
		}
	}

	
	private Principal getUser(WebSocketSession session) {
		Principal user = this.stompAuthentications.get(session.getId());
		return (user !is null ? user : session.getPrincipal());
	}

	private void handleError(WebSocketSession session, Throwable ex, Message!(byte[]) clientMessage) {
		if (getErrorHandler() is null) {
			sendErrorMessage(session, ex);
			return;
		}

		Message!(byte[]) message = getErrorHandler().handleClientMessageProcessingError(clientMessage, ex);
		if (message is null) {
			return;
		}

		StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
		assert(accessor !is null, "No StompHeaderAccessor");
		sendToClient(session, accessor, message.getPayload());
	}

	/**
	 * Invoked when no
	 * {@link #setErrorHandler(StompSubProtocolErrorHandler) errorHandler}
	 * is configured to send an ERROR frame to the client.
	 */
	private void sendErrorMessage(WebSocketSession session, Throwable error) {
		StompHeaderAccessor headerAccessor = StompHeaderAccessor.create(StompCommand.ERROR);
		headerAccessor.setMessage(error.getMessage());

		byte[] bytes = this.stompEncoder.encode(headerAccessor.getMessageHeaders(), EMPTY_PAYLOAD);
		try {
			session.sendMessage(new TextMessage(bytes));
		}
		catch (Throwable ex) {
			// Could be part of normal workflow (e.g. browser tab closed)
			trace("Failed to send STOMP ERROR to client", ex);
		}
	}

	private bool detectImmutableMessageInterceptor(MessageChannel channel) {
		if (this.immutableMessageInterceptorPresent !is null) {
			return this.immutableMessageInterceptorPresent;
		}

		if (channel instanceof AbstractMessageChannel) {
			for (ChannelInterceptor interceptor : ((AbstractMessageChannel) channel).getInterceptors()) {
				if (interceptor instanceof ImmutableMessageChannelInterceptor) {
					this.immutableMessageInterceptorPresent = true;
					return true;
				}
			}
		}
		this.immutableMessageInterceptorPresent = false;
		return false;
	}

	private void publishEvent(ApplicationEventPublisher publisher, ApplicationEvent event) {
		try {
			publisher.publishEvent(event);
		}
		catch (Throwable ex) {
			version(HUNT_DEBUG) {
				errorf("Error publishing " ~ event, ex);
			}
		}
	}

	/**
	 * Handle STOMP messages going back out to WebSocket clients.
	 */
	override
	
	void handleMessageToClient(WebSocketSession session, MessageBase message) {
		if (!(message.getPayload() instanceof byte[])) {
			version(HUNT_DEBUG) {
				errorf("Expected byte[] payload. Ignoring " ~ message ~ ".");
			}
			return;
		}

		StompHeaderAccessor accessor = getStompHeaderAccessor(message);
		StompCommand command = accessor.getCommand();

		if (StompCommand.MESSAGE.equals(command)) {
			if (accessor.getSubscriptionId() is null && logger.isWarnEnabled()) {
				logger.warn("No STOMP \"subscription\" header in " ~ message);
			}
			string origDestination = accessor.getFirstNativeHeader(SimpMessageHeaderAccessor.ORIGINAL_DESTINATION);
			if (origDestination !is null) {
				accessor = toMutableAccessor(accessor, message);
				accessor.removeNativeHeader(SimpMessageHeaderAccessor.ORIGINAL_DESTINATION);
				accessor.setDestination(origDestination);
			}
		}
		else if (StompCommand.CONNECTED.equals(command)) {
			this.stats.incrementConnectedCount();
			accessor = afterStompSessionConnected(message, accessor, session);
			if (this.eventPublisher !is null && StompCommand.CONNECTED.equals(command)) {
				try {
					SimpAttributes simpAttributes = new SimpAttributes(session.getId(), session.getAttributes());
					SimpAttributesContextHolder.setAttributes(simpAttributes);
					Principal user = getUser(session);
					publishEvent(this.eventPublisher, new SessionConnectedEvent(this, (Message!(byte[])) message, user));
				}
				finally {
					SimpAttributesContextHolder.resetAttributes();
				}
			}
		}

		byte[] payload = (byte[]) message.getPayload();
		if (StompCommand.ERROR.equals(command) && getErrorHandler() !is null) {
			Message!(byte[]) errorMessage = getErrorHandler().handleErrorMessageToClient((Message!(byte[])) message);
			if (errorMessage !is null) {
				accessor = MessageHeaderAccessor.getAccessor(errorMessage, StompHeaderAccessor.class);
				assert(accessor !is null, "No StompHeaderAccessor");
				payload = errorMessage.getPayload();
			}
		}
		sendToClient(session, accessor, payload);
	}

	private void sendToClient(WebSocketSession session, StompHeaderAccessor stompAccessor, byte[] payload) {
		StompCommand command = stompAccessor.getCommand();
		try {
			byte[] bytes = this.stompEncoder.encode(stompAccessor.getMessageHeaders(), payload);
			booluseBinary = (payload.length > 0 && !(session instanceof SockJsSession) &&
					MimeTypeUtils.APPLICATION_OCTET_STREAM.isCompatibleWith(stompAccessor.getContentType()));
			if (useBinary) {
				session.sendMessage(new BinaryMessage(bytes));
			}
			else {
				session.sendMessage(new TextMessage(bytes));
			}
		}
		catch (SessionLimitExceededException ex) {
			// Bad session, just get out
			throw ex;
		}
		catch (Throwable ex) {
			// Could be part of normal workflow (e.g. browser tab closed)
			version(HUNT_DEBUG) {
				trace("Failed to send WebSocket message to client in session " ~ session.getId(), ex);
			}
			command = StompCommand.ERROR;
		}
		finally {
			if (StompCommand.ERROR.equals(command)) {
				try {
					session.close(CloseStatus.PROTOCOL_ERROR);
				}
				catch (IOException ex) {
					// Ignore
				}
			}
		}
	}

	private StompHeaderAccessor getStompHeaderAccessor(MessageBase message) {
		MessageHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, MessageHeaderAccessor.class);
		if (accessor instanceof StompHeaderAccessor) {
			return (StompHeaderAccessor) accessor;
		}
		else {
			StompHeaderAccessor stompAccessor = StompHeaderAccessor.wrap(message);
			SimpMessageType messageType = SimpMessageHeaderAccessor.getMessageType(message.getHeaders());
			if (SimpMessageType.CONNECT_ACK.equals(messageType)) {
				stompAccessor = convertConnectAcktoStompConnected(stompAccessor);
			}
			else if (SimpMessageType.DISCONNECT_ACK.equals(messageType)) {
				string receipt = getDisconnectReceipt(stompAccessor);
				if (receipt !is null) {
					stompAccessor = StompHeaderAccessor.create(StompCommand.RECEIPT);
					stompAccessor.setReceiptId(receipt);
				}
				else {
					stompAccessor = StompHeaderAccessor.create(StompCommand.ERROR);
					stompAccessor.setMessage("Session closed.");
				}
			}
			else if (SimpMessageType.HEARTBEAT.equals(messageType)) {
				stompAccessor = StompHeaderAccessor.createForHeartbeat();
			}
			else if (stompAccessor.getCommand() is null || StompCommand.SEND.equals(stompAccessor.getCommand())) {
				stompAccessor.updateStompCommandAsServerMessage();
			}
			return stompAccessor;
		}
	}

	/**
	 * The simple broker produces {@code SimpMessageType.CONNECT_ACK} that's not STOMP
	 * specific and needs to be turned into a STOMP CONNECTED frame.
	 */
	private StompHeaderAccessor convertConnectAcktoStompConnected(StompHeaderAccessor connectAckHeaders) {
		string name = StompHeaderAccessor.CONNECT_MESSAGE_HEADER;
		MessageBase message = (MessageBase) connectAckHeaders.getHeader(name);
		if (message is null) {
			throw new IllegalStateException("Original STOMP CONNECT not found in " ~ connectAckHeaders);
		}

		StompHeaderAccessor connectHeaders = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
		StompHeaderAccessor connectedHeaders = StompHeaderAccessor.create(StompCommand.CONNECTED);

		if (connectHeaders !is null) {
			Set!(string) acceptVersions = connectHeaders.getAcceptVersion();
			connectedHeaders.setVersion(
					Arrays.stream(SUPPORTED_VERSIONS)
							.filter(acceptVersions::contains)
							.findAny()
							.orElseThrow(() -> new IllegalArgumentException(
									"Unsupported STOMP version '" ~ acceptVersions ~ "'")));
		}

		long[] heartbeat = (long[]) connectAckHeaders.getHeader(SimpMessageHeaderAccessor.HEART_BEAT_HEADER);
		if (heartbeat !is null) {
			connectedHeaders.setHeartbeat(heartbeat[0], heartbeat[1]);
		}
		else {
			connectedHeaders.setHeartbeat(0, 0);
		}

		return connectedHeaders;
	}

	
	private string getDisconnectReceipt(SimpMessageHeaderAccessor simpHeaders) {
		string name = StompHeaderAccessor.DISCONNECT_MESSAGE_HEADER;
		MessageBase message = (MessageBase) simpHeaders.getHeader(name);
		if (message !is null) {
			StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
			if (accessor !is null) {
				return accessor.getReceipt();
			}
		}
		return null;
	}

	protected StompHeaderAccessor toMutableAccessor(StompHeaderAccessor headerAccessor, MessageBase message) {
		return (headerAccessor.isMutable() ? headerAccessor : StompHeaderAccessor.wrap(message));
	}

	private StompHeaderAccessor afterStompSessionConnected(MessageBase message, StompHeaderAccessor accessor,
			WebSocketSession session) {

		Principal principal = getUser(session);
		if (principal !is null) {
			accessor = toMutableAccessor(accessor, message);
			accessor.setNativeHeader(CONNECTED_USER_HEADER, principal.getName());
		}

		long[] heartbeat = accessor.getHeartbeat();
		if (heartbeat[1] > 0) {
			session = WebSocketSessionDecorator.unwrap(session);
			if (session instanceof SockJsSession) {
				((SockJsSession) session).disableHeartbeat();
			}
		}

		return accessor;
	}

	override
	
	string resolveSessionId(MessageBase message) {
		return SimpMessageHeaderAccessor.getSessionId(message.getHeaders());
	}

	override
	void afterSessionStarted(WebSocketSession session, MessageChannel outputChannel) {
		if (session.getTextMessageSizeLimit() < MINIMUM_WEBSOCKET_MESSAGE_SIZE) {
			session.setTextMessageSizeLimit(MINIMUM_WEBSOCKET_MESSAGE_SIZE);
		}
		this.decoders.put(session.getId(), new BufferingStompDecoder(this.stompDecoder, getMessageSizeLimit()));
	}

	override
	void afterSessionEnded(WebSocketSession session, CloseStatus closeStatus, MessageChannel outputChannel) {
		this.decoders.remove(session.getId());

		Message!(byte[]) message = createDisconnectMessage(session);
		SimpAttributes simpAttributes = SimpAttributes.fromMessage(message);
		try {
			SimpAttributesContextHolder.setAttributes(simpAttributes);
			if (this.eventPublisher !is null) {
				Principal user = getUser(session);
				publishEvent(this.eventPublisher, new SessionDisconnectEvent(this, message, session.getId(), closeStatus, user));
			}
			outputChannel.send(message);
		}
		finally {
			this.stompAuthentications.remove(session.getId());
			SimpAttributesContextHolder.resetAttributes();
			simpAttributes.sessionCompleted();
		}
	}

	private Message!(byte[]) createDisconnectMessage(WebSocketSession session) {
		StompHeaderAccessor headerAccessor = StompHeaderAccessor.create(StompCommand.DISCONNECT);
		if (getHeaderInitializer() !is null) {
			getHeaderInitializer().initHeaders(headerAccessor);
		}

		headerAccessor.setSessionId(session.getId());
		headerAccessor.setSessionAttributes(session.getAttributes());

		Principal user = getUser(session);
		if (user !is null) {
			headerAccessor.setUser(user);
		}

		return MessageHelper.createMessage(EMPTY_PAYLOAD, headerAccessor.getMessageHeaders());
	}

	override
	string toString() {
		return "StompSubProtocolHandler" ~ getSupportedProtocols();
	}


	// private static class Stats {

	// 	private AtomicInteger connect = new AtomicInteger();

	// 	private AtomicInteger connected = new AtomicInteger();

	// 	private AtomicInteger disconnect = new AtomicInteger();

	// 	void incrementConnectCount() {
	// 		this.connect.incrementAndGet();
	// 	}

	// 	void incrementConnectedCount() {
	// 		this.connected.incrementAndGet();
	// 	}

	// 	void incrementDisconnectCount() {
	// 		this.disconnect.incrementAndGet();
	// 	}

	// 	string toString() {
	// 		return "processed CONNECT(" ~ this.connect.get() ~ ")-CONNECTED(" ~
	// 				this.connected.get() ~ ")-DISCONNECT(" ~ this.disconnect.get() ~ ")";
	// 	}
	// }

}
