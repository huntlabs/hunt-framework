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

module hunt.framework.messaging.simp.stomp.DefaultStompSession;

import hunt.framework.messaging.simp.stomp.StompCommand;
import hunt.framework.messaging.simp.stomp.StompDecoder;
import hunt.framework.messaging.simp.stomp.StompHeaders;
import hunt.framework.messaging.simp.stomp.StompSessionHandler;

import hunt.framework.messaging.exception;
import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessagingException;
import hunt.framework.messaging.converter.MessageConverter;
import hunt.framework.messaging.converter.SimpleMessageConverter;
// 
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;
// import hunt.framework.messaging.tcp.TcpConnection;
import hunt.framework.messaging.IdGenerator;

// import java.lang.reflect.Type;
// import java.util.ArrayList;
// import hunt.container.Collections;
// import java.util.Date;
// import java.util.List;
// import hunt.container.Map;
// import java.util.concurrent.ConcurrentHashMap;
// import java.util.concurrent.ExecutionException;
// import java.util.concurrent.ScheduledFuture;
// import java.util.concurrent.TimeUnit;
// import java.util.concurrent.atomic.AtomicInteger;

import hunt.framework.task.TaskScheduler;

import hunt.container;
import hunt.datetime;
import hunt.lang.common;
import hunt.lang.exception;
import hunt.lang.Nullable;
import hunt.logging;

import std.algorithm;
import std.datetime;
import std.uuid;

// import hunt.framework.core.ResolvableType;

// import hunt.framework.util.AlternativeJdkIdGenerator;
// import hunt.framework.util.IdGenerator;
// import hunt.framework.util.StringUtils;
// import hunt.framework.util.concurrent.ListenableFuture;
// import hunt.framework.util.concurrent.ListenableFutureCallback;
// import hunt.framework.util.concurrent.SettableListenableFuture;

/**
 * Default implementation of {@link ConnectionHandlingStompSession}.
 *
 * @author Rossen Stoyanchev
 * @since 4.2
 */
// class DefaultStompSession : ConnectionHandlingStompSession {

// 	private __gshared IdGenerator idGenerator; //  = new AlternativeJdkIdGenerator();

// 	/**
// 	 * An empty payload.
// 	 */
// 	enum byte[] EMPTY_PAYLOAD = [];

// 	/* STOMP spec: receiver SHOULD take into account an error margin */
// 	private enum long HEARTBEAT_MULTIPLIER = 3;

// 	private __gshared Message!(byte[]) HEARTBEAT;

// 	shared static this() {
// 		idGenerator = new class IdGenerator {
// 			UUID generateId() {
// 				return randomUUID();
// 			}
// 		};

// 		StompHeaderAccessor accessor = StompHeaderAccessor.createForHeartbeat();
// 		HEARTBEAT = MessageHelper.createMessage(StompDecoder.HEARTBEAT_PAYLOAD, accessor.getMessageHeaders());
// 	}


// 	private string sessionId;

// 	private StompSessionHandler sessionHandler;

// 	private StompHeaders connectHeaders;

// 	// private SettableListenableFuture!(StompSession) sessionFuture = new SettableListenableFuture<>();
// 	// private StompSession sessionFuture;

// 	private MessageConverter converter;
	
// 	private TaskScheduler taskScheduler;

// 	private long receiptTimeLimit; // = TimeUnit.SECONDS.toMillis(15);

// 	private bool autoReceiptEnabled;
	
// 	private TcpConnection!(byte[]) connection;

	
// 	private string ver;

// 	private shared int subscriptionIndex; // = new AtomicInteger();

// 	private Map!(string, DefaultSubscription) subscriptions; // = new ConcurrentHashMap<>(4);

// 	private shared int receiptIndex; // = new AtomicInteger();

// 	private Map!(string, ReceiptHandler) receiptHandlers; // = new ConcurrentHashMap<>(4);

// 	/* Whether the client is willfully closing the connection */
// 	private bool closing = false;


// 	/**
// 	 * Create a new session.
// 	 * @param sessionHandler the application handler for the session
// 	 * @param connectHeaders headers for the STOMP CONNECT frame
// 	 */
// 	this(StompSessionHandler sessionHandler, StompHeaders connectHeaders) {
// 		assert(sessionHandler, "StompSessionHandler must not be null");
// 		assert(connectHeaders, "StompHeaders must not be null");
// 		subscriptions = new HashMap!(string, DefaultSubscription)(4);
// 		receiptHandlers = new HashMap!(string, ReceiptHandler)(4);

// 		converter = new SimpleMessageConverter();
// 		receiptTimeLimit = convert!(TimeUnit.Second, TimeUnit.Millisecond)(15);
// 		this.sessionId = idGenerator.generateId().toString();
// 		this.sessionHandler = sessionHandler;
// 		this.connectHeaders = connectHeaders;
// 	}


// 	override
// 	string getSessionId() {
// 		return this.sessionId;
// 	}

// 	/**
// 	 * Return the configured session handler.
// 	 */
// 	StompSessionHandler getSessionHandler() {
// 		return this.sessionHandler;
// 	}

// 	// override
// 	// ListenableFuture!(StompSession) getSessionFuture() {
// 	// 	return this.sessionFuture;
// 	// }

// 	/**
// 	 * Set the {@link MessageConverter} to use to convert the payload of incoming
// 	 * and outgoing messages to and from {@code byte[]} based on object type, or
// 	 * expected object type, and the "content-type" header.
// 	 * <p>By default, {@link SimpleMessageConverter} is configured.
// 	 * @param messageConverter the message converter to use
// 	 */
// 	void setMessageConverter(MessageConverter messageConverter) {
// 		assert(messageConverter, "MessageConverter must not be null");
// 		this.converter = messageConverter;
// 	}

// 	/**
// 	 * Return the configured {@link MessageConverter}.
// 	 */
// 	MessageConverter getMessageConverter() {
// 		return this.converter;
// 	}

// 	/**
// 	 * Configure the TaskScheduler to use for receipt tracking.
// 	 */
// 	void setTaskScheduler(TaskScheduler taskScheduler) {
// 		this.taskScheduler = taskScheduler;
// 	}

// 	/**
// 	 * Return the configured TaskScheduler to use for receipt tracking.
// 	 */
	
// 	TaskScheduler getTaskScheduler() {
// 		return this.taskScheduler;
// 	}

// 	/**
// 	 * Configure the time in milliseconds before a receipt expires.
// 	 * <p>By default set to 15,000 (15 seconds).
// 	 */
// 	void setReceiptTimeLimit(long receiptTimeLimit) {
// 		assert(receiptTimeLimit > 0, "Receipt time limit must be larger than zero");
// 		this.receiptTimeLimit = receiptTimeLimit;
// 	}

// 	/**
// 	 * Return the configured time limit before a receipt expires.
// 	 */
// 	long getReceiptTimeLimit() {
// 		return this.receiptTimeLimit;
// 	}

// 	override
// 	void setAutoReceipt(bool autoReceiptEnabled) {
// 		this.autoReceiptEnabled = autoReceiptEnabled;
// 	}

// 	/**
// 	 * Whether receipt headers should be automatically added.
// 	 */
// 	bool isAutoReceiptEnabled() {
// 		return this.autoReceiptEnabled;
// 	}

// 	override
// 	bool isConnected() {
// 		return (this.connection !is null);
// 	}

// 	override
// 	Receiptable send(string destination, Object payload) {
// 		StompHeaders headers = new StompHeaders();
// 		headers.setDestination(destination);
// 		return send(headers, payload);
// 	}

// 	override
// 	Receiptable send(StompHeaders headers, Object payload) {
// 		Assert.hasText(headers.getDestination(), "Destination header is required");

// 		string receiptId = checkOrAddReceipt(headers);
// 		Receiptable receiptable = new ReceiptHandler(receiptId);

// 		StompHeaderAccessor accessor = createHeaderAccessor(StompCommand.SEND);
// 		accessor.addNativeHeaders(headers);
// 		Message!(byte[]) message = createMessage(accessor, payload);
// 		execute(message);

// 		return receiptable;
// 	}

	
// 	private string checkOrAddReceipt(StompHeaders headers) {
// 		string receiptId = headers.getReceipt();
// 		if (isAutoReceiptEnabled() && receiptId is null) {
// 			receiptId = to!string(this.outer.receiptIndex++);
// 			headers.setReceipt(receiptId);
// 		}
// 		return receiptId;
// 	}

// 	private StompHeaderAccessor createHeaderAccessor(StompCommand command) {
// 		StompHeaderAccessor accessor = StompHeaderAccessor.create(command);
// 		accessor.setSessionId(this.sessionId);
// 		accessor.setLeaveMutable(true);
// 		return accessor;
// 	}

	
// 	private Message!(byte[]) createMessage(StompHeaderAccessor accessor, Object payload) {
// 		accessor.updateSimpMessageHeadersFromStompHeaders();
// 		Message!(byte[]) message;
// 		if (payload is null) {
// 			message = MessageHelper.createMessage(EMPTY_PAYLOAD, accessor.getMessageHeaders());
// 		}
// 		else {
// 			auto pl = cast(Nullable!(byte[])) payload;
// 			if (pl !is null) {
// 				message = MessageHelper.createMessage(pl.value(), accessor.getMessageHeaders());
// 			}
// 			else {
// 				message = cast(Message!(byte[])) getMessageConverter().toMessage(payload, accessor.getMessageHeaders());
// 				accessor.updateStompHeadersFromSimpMessageHeaders();
// 				if (message is null) {
// 					throw new MessageConversionException("Unable to convert payload with type='" ~
// 							typeid(payload).name ~ "', contentType='" ~ accessor.getContentType() ~
// 							"', converter=[" ~ getMessageConverter() ~ "]");
// 				}
// 			}
// 		} 
// 		return message;
// 	}

// 	private void execute(Message!(byte[]) message) {
// 		version(HUNT_DEBUG) {
// 			StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor!StompHeaderAccessor(message);
// 			if (accessor !is null) {
// 				trace("Sending " ~ accessor.getDetailedLogMessage(message.getPayload()));
// 			}
// 		}
// 		TcpConnection!(byte[]) conn = this.connection;
// 		assert(conn !is null, "Connection closed");
// 		try {
// 			conn.send(message).get();
// 		}
// 		catch (ExecutionException ex) {
// 			throw new MessageDeliveryException(message, ex.getCause());
// 		}
// 		catch (Throwable ex) {
// 			throw new MessageDeliveryException(message, ex);
// 		}
// 	}

// 	override
// 	Subscription subscribe(string destination, StompFrameHandler handler) {
// 		StompHeaders headers = new StompHeaders();
// 		headers.setDestination(destination);
// 		return subscribe(headers, handler);
// 	}

// 	override
// 	Subscription subscribe(StompHeaders headers, StompFrameHandler handler) {
// 		Assert.hasText(headers.getDestination(), "Destination header is required");
// 		assert(handler, "StompFrameHandler must not be null");

// 		string subscriptionId = headers.getId();
// 		if (!StringUtils.hasText(subscriptionId)) {
// 			subscriptionId = string.valueOf(this.outer.subscriptionIndex++);
// 			headers.setId(subscriptionId);
// 		}
// 		checkOrAddReceipt(headers);
// 		Subscription subscription = new DefaultSubscription(headers, handler);

// 		StompHeaderAccessor accessor = createHeaderAccessor(StompCommand.SUBSCRIBE);
// 		accessor.addNativeHeaders(headers);
// 		Message!(byte[]) message = createMessage(accessor, EMPTY_PAYLOAD);
// 		execute(message);

// 		return subscription;
// 	}

// 	override
// 	Receiptable acknowledge(string messageId,  consumed) {
// 		StompHeaders headers = new StompHeaders();
// 		if ("1.1".equals(this.ver)) {
// 			headers.setMessageId(messageId);
// 		}
// 		else {
// 			headers.setId(messageId);
// 		}
// 		return acknowledge(headers, consumed);
// 	}

// 	override
// 	Receiptable acknowledge(StompHeaders headers,  consumed) {
// 		string receiptId = checkOrAddReceipt(headers);
// 		Receiptable receiptable = new ReceiptHandler(receiptId);

// 		StompCommand command = (consumed ? StompCommand.ACK : StompCommand.NACK);
// 		StompHeaderAccessor accessor = createHeaderAccessor(command);
// 		accessor.addNativeHeaders(headers);
// 		Message!(byte[]) message = createMessage(accessor, null);
// 		execute(message);

// 		return receiptable;
// 	}

// 	private void unsubscribe(string id, StompHeaders headers) {
// 		StompHeaderAccessor accessor = createHeaderAccessor(StompCommand.UNSUBSCRIBE);
// 		if (headers !is null) {
// 			accessor.addNativeHeaders(headers);
// 		}
// 		accessor.setSubscriptionId(id);
// 		Message!(byte[]) message = createMessage(accessor, EMPTY_PAYLOAD);
// 		execute(message);
// 	}

// 	override
// 	void disconnect() {
// 		this.closing = true;
// 		try {
// 			StompHeaderAccessor accessor = createHeaderAccessor(StompCommand.DISCONNECT);
// 			Message!(byte[]) message = createMessage(accessor, EMPTY_PAYLOAD);
// 			execute(message);
// 		}
// 		finally {
// 			resetConnection();
// 		}
// 	}


// 	// TcpConnectionHandler

// 	override
// 	void afterConnected(TcpConnection!(byte[]) connection) {
// 		this.connection = connection;
// 		version(HUNT_DEBUG) {
// 			trace("Connection established in session id=" ~ this.sessionId);
// 		}
// 		StompHeaderAccessor accessor = createHeaderAccessor(StompCommand.CONNECT);
// 		accessor.addNativeHeaders(this.connectHeaders);
// 		if (this.connectHeaders.getAcceptVersion() is null) {
// 			accessor.setAcceptVersion("1.1,1.2");
// 		}
// 		Message!(byte[]) message = createMessage(accessor, EMPTY_PAYLOAD);
// 		execute(message);
// 	}

// 	override
// 	void afterConnectFailure(Throwable ex) {
// 		version(HUNT_DEBUG) {
// 			trace("Failed to connect session id=" ~ this.sessionId, ex);
// 		}
// 		// this.sessionFuture.setException(ex);
// 		this.sessionHandler.handleTransportError(this, ex);
// 	}

// 	override
// 	void handleMessage(Message!(byte[]) message) {
// 		StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor!(StompHeaderAccessor)(message);
// 		assert(accessor !is null, "No StompHeaderAccessor");

// 		accessor.setSessionId(this.sessionId);
// 		StompCommand command = accessor.getCommand();
// 		Map!(string, List!(string)) nativeHeaders = accessor.getNativeHeaders();
// 		StompHeaders headers = StompHeaders.readOnlyStompHeaders(nativeHeaders);
// 		 isHeartbeat = accessor.isHeartbeat();
// 		version(HUNT_DEBUG) {
// 			trace("Received " ~ accessor.getDetailedLogMessage(message.getPayload()));
// 		}

// 		try {
// 			if (StompCommand.MESSAGE == command) {
// 				DefaultSubscription subscription = this.subscriptions.get(headers.getSubscription());
// 				if (subscription !is null) {
// 					invokeHandler(subscription.getHandler(), message, headers);
// 				}
// 				else version(HUNT_DEBUG) {
// 					trace("No handler for: " ~ accessor.getDetailedLogMessage(message.getPayload()) ~
// 							". Perhaps just unsubscribed?");
// 				}
// 			}
// 			else {
// 				if (StompCommand.RECEIPT == command) {
// 					string receiptId = headers.getReceiptId();
// 					ReceiptHandler handler = this.receiptHandlers.get(receiptId);
// 					if (handler !is null) {
// 						handler.handleReceiptReceived();
// 					}
// 					else version(HUNT_DEBUG) {
// 						trace("No matching receipt: " ~ accessor.getDetailedLogMessage(message.getPayload()));
// 					}
// 				}
// 				else if (StompCommand.CONNECTED == command) {
// 					initHeartbeatTasks(headers);
// 					this.ver = headers.getFirst("version");
// 					// this.sessionFuture.set(this);
// 					this.sessionHandler.afterConnected(this, headers);
// 				}
// 				else if (StompCommand.ERROR == command) {
// 					invokeHandler(this.sessionHandler, message, headers);
// 				}
// 				else if (!isHeartbeat && logger.isTraceEnabled()) {
// 					trace("Message not handled.");
// 				}
// 			}
// 		}
// 		catch (Throwable ex) {
// 			this.sessionHandler.handleException(this, command, headers, message.getPayload(), ex);
// 		}
// 	}

// 	private void invokeHandler(StompFrameHandler handler, 
// 		Message!(byte[]) message, StompHeaders headers) {
// 		if (message.getPayload().length == 0) {
// 			handler.handleFrame(headers, null);
// 			return;
// 		}
// 		// Type payloadType = handler.getPayloadType(headers);
// 		// Class<?> resolvedType = ResolvableType.forType(payloadType).resolve();
// 		// if (resolvedType is null) {
// 		// 	throw new MessageConversionException("Unresolvable payload type [" ~ payloadType +
// 		// 			"] from handler type [" ~ handler.getClass() ~ "]");
// 		// }
// 		// Object object = getMessageConverter().fromMessage(message, resolvedType);
// 		// if (object is null) {
// 		// 	throw new MessageConversionException("No suitable converter for payload type [" ~ payloadType +
// 		// 			"] from handler type [" ~ handler.getClass() ~ "]");
// 		// }
// 		// handler.handleFrame(headers, object);
		
// 	}

// 	private void initHeartbeatTasks(StompHeaders connectedHeaders) {
// 		long[] connect = this.connectHeaders.getHeartbeat();
// 		long[] connected = connectedHeaders.getHeartbeat();
// 		if (connect is null || connected is null) {
// 			return;
// 		}
// 		// TODO: Tasks pending completion -@zxp at 10/30/2018, 3:10:33 PM
// 		// 
// 		// TcpConnection!(byte[]) con = this.connection;
// 		// assert(con !is null, "No TcpConnection available");
// 		// if (connect[0] > 0 && connected[1] > 0) {
// 		// 	long interval = max(connect[0],  connected[1]);
// 		// 	con.onWriteInactivity(new WriteInactivityTask(), interval);
// 		// }
// 		// if (connect[1] > 0 && connected[0] > 0) {
// 		// 	long interval = max(connect[1], connected[0]) * HEARTBEAT_MULTIPLIER;
// 		// 	con.onReadInactivity(new ReadInactivityTask(), interval);
// 		// }
// 	}

// 	override
// 	void handleFailure(Throwable ex) {
// 		try {
// 			// this.sessionFuture.setException(ex);  // no-op if already set
// 			this.sessionHandler.handleTransportError(this, ex);
// 		}
// 		catch (Throwable ex2) {
// 			version(HUNT_DEBUG) {
// 				trace("Uncaught failure while handling transport failure", ex2);
// 			}
// 		}
// 	}

// 	override
// 	void afterConnectionClosed() {
// 		version(HUNT_DEBUG) {
// 			trace("Connection closed in session id=" ~ this.sessionId);
// 		}
// 		if (!this.closing) {
// 			resetConnection();
// 			handleFailure(new ConnectionLostException("Connection closed"));
// 		}
// 	}

// 	private void resetConnection() {
// 		implementationMissing(false);
// 		// TcpConnection<?> conn = this.connection;
// 		// this.connection = null;
// 		// if (conn !is null) {
// 		// 	try {
// 		// 		conn.close();
// 		// 	}
// 		// 	catch (Throwable ex) {
// 		// 		// ignore
// 		// 	}
// 		// }
// 	}


// 	private class ReceiptHandler : Receiptable {

		
// 		private string receiptId;

// 		private Runnable[] receiptCallbacks;

// 		private Runnable[] receiptLostCallbacks;
		
// 		// private ScheduledFuture<?> future;
		
// 		private bool result;

// 		this(string receiptId) {
// 			this.receiptId = receiptId;
// 			if (receiptId !is null) {
// 				initReceiptHandling();
// 			}
// 		}

// 		private void initReceiptHandling() {
// 			assert(getTaskScheduler(), "To track receipts, a TaskScheduler must be configured");
// 			this.outer.receiptHandlers.put(this.receiptId, this);
// 			Date startTime = new Date(DateTimeHelper.currentTimeMillis + getReceiptTimeLimit());
// 			// this.future = getTaskScheduler().schedule(this::handleReceiptNotReceived, startTime);
// 		}

// 		override
// 		string getReceiptId() {
// 			return this.receiptId;
// 		}

// 		override
// 		void addReceiptTask(Runnable task) {
// 			addTask(task, true);
// 		}

// 		override
// 		void addReceiptLostTask(Runnable task) {
// 			addTask(task, false);
// 		}

// 		private void addTask(Runnable task,  successTask) {
// 			assert(this.receiptId,
// 					"To track receipts, set autoReceiptEnabled=true or add 'receiptId' header");
// 			synchronized (this) {
// 				if (this.result !is null && this.result == successTask) {
// 					invoke([task]);
// 				}
// 				else {
// 					if (successTask) {
// 						this.receiptCallbacks ~= task;
// 					}
// 					else {
// 						this.receiptLostCallbacks ~= task;
// 					}
// 				}
// 			}
// 		}

// 		private void invoke(Runnable[] callbacks) {
// 			foreach (Runnable runnable ; callbacks) {
// 				try {
// 					runnable.run();
// 				}
// 				catch (Throwable ex) {
// 					// ignore
// 				}
// 			}
// 		}

// 		void handleReceiptReceived() {
// 			handleInternal(true);
// 		}

// 		void handleReceiptNotReceived() {
// 			handleInternal(false);
// 		}

// 		private void handleInternal(bool result) {
// 			synchronized (this) {
// 				if (this.result !is null) {
// 					return;
// 				}
// 				this.result = result;
// 				invoke(result ? this.receiptCallbacks : this.receiptLostCallbacks);
// 				this.outer.receiptHandlers.remove(this.receiptId);
// 				if (this.future !is null) {
// 					this.future.cancel(true);
// 				}
// 			}
// 		}
// 	}


// 	private class DefaultSubscription : ReceiptHandler, Subscription {

// 		private StompHeaders headers;

// 		private StompFrameHandler handler;

// 		this(StompHeaders headers, StompFrameHandler handler) {
// 			super(headers.getReceipt());
// 			assert(headers.getDestination(), "Destination must not be null");
// 			assert(handler, "StompFrameHandler must not be null");
// 			this.headers = headers;
// 			this.handler = handler;
// 			this.outer.subscriptions.put(headers.getId(), this);
// 		}

// 		override
// 		string getSubscriptionId() {
// 			return this.headers.getId();
// 		}

// 		override
// 		StompHeaders getSubscriptionHeaders() {
// 			return this.headers;
// 		}

// 		StompFrameHandler getHandler() {
// 			return this.handler;
// 		}

// 		override
// 		void unsubscribe() {
// 			unsubscribe(null);
// 		}

// 		override
// 		void unsubscribe(StompHeaders headers) {
// 			string id = this.headers.getId();
// 			if (id !is null) {
// 				this.outer.subscriptions.remove(id);
// 				this.outer.unsubscribe(id, headers);
// 			}
// 		}

// 		override
// 		string toString() {
// 			return "Subscription [id=" ~ getSubscriptionId() +
// 					", destination='" ~ this.headers.getDestination() +
// 					"', receiptId='" ~ getReceiptId() ~ "', handler=" ~ getHandler() ~ "]";
// 		}
// 	}


// 	private class WriteInactivityTask : Runnable {

// 		override
// 		void run() {
// 			implementationMissing(false);
// 			// TcpConnection!(byte[]) conn = connection;
// 			// if (conn !is null) {
// 			// 	conn.send(HEARTBEAT).addCallback(
// 			// 			new ListenableFutureCallback!(Void)() {
// 			// 				void onSuccess(Void result) {
// 			// 				}
// 			// 				void onFailure(Throwable ex) {
// 			// 					handleFailure(ex);
// 			// 				}
// 			// 			});
// 			// }
// 		}
// 	}


// 	private class ReadInactivityTask : Runnable {

// 		override
// 		void run() {
// 			closing = true;
// 			string error = "Server has gone quiet. Closing connection in session id=" ~ sessionId ~ ".";
// 			version(HUNT_DEBUG) {
// 				trace(error);
// 			}
// 			resetConnection();
// 			handleFailure(new IllegalStateException(error));
// 		}
// 	}

// }
