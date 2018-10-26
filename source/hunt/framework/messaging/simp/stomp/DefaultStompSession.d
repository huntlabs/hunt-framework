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

module hunt.framework.messaging.simp.stomp;

import java.lang.reflect.Type;
import java.util.ArrayList;
import hunt.container.Collections;
import java.util.Date;
import java.util.List;
import hunt.container.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import hunt.logging;

import hunt.framework.core.ResolvableType;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageDeliveryException;
import hunt.framework.messaging.converter.MessageConversionException;
import hunt.framework.messaging.converter.MessageConverter;
import hunt.framework.messaging.converter.SimpleMessageConverter;
import hunt.framework.messaging.simp.SimpLogging;
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;
import hunt.framework.messaging.tcp.TcpConnection;
import hunt.framework.scheduling.TaskScheduler;
import hunt.framework.util.AlternativeJdkIdGenerator;

import hunt.framework.util.IdGenerator;
import hunt.framework.util.StringUtils;
import hunt.framework.util.concurrent.ListenableFuture;
import hunt.framework.util.concurrent.ListenableFutureCallback;
import hunt.framework.util.concurrent.SettableListenableFuture;

/**
 * Default implementation of {@link ConnectionHandlingStompSession}.
 *
 * @author Rossen Stoyanchev
 * @since 4.2
 */
public class DefaultStompSession implements ConnectionHandlingStompSession {



	private static final IdGenerator idGenerator = new AlternativeJdkIdGenerator();

	/**
	 * An empty payload.
	 */
	public static final byte[] EMPTY_PAYLOAD = new byte[0];

	/* STOMP spec: receiver SHOULD take into account an error margin */
	private static final long HEARTBEAT_MULTIPLIER = 3;

	private static final Message!(byte[]) HEARTBEAT;

	static {
		StompHeaderAccessor accessor = StompHeaderAccessor.createForHeartbeat();
		HEARTBEAT = MessageBuilder.createMessage(StompDecoder.HEARTBEAT_PAYLOAD, accessor.getMessageHeaders());
	}


	private final string sessionId;

	private final StompSessionHandler sessionHandler;

	private final StompHeaders connectHeaders;

	private final SettableListenableFuture!(StompSession) sessionFuture = new SettableListenableFuture<>();

	private MessageConverter converter = new SimpleMessageConverter();

	
	private TaskScheduler taskScheduler;

	private long receiptTimeLimit = TimeUnit.SECONDS.toMillis(15);

	private bool autoReceiptEnabled;


	
	private TcpConnection!(byte[]) connection;

	
	private string version;

	private final AtomicInteger subscriptionIndex = new AtomicInteger();

	private final Map!(string, DefaultSubscription) subscriptions = new ConcurrentHashMap<>(4);

	private final AtomicInteger receiptIndex = new AtomicInteger();

	private final Map!(string, ReceiptHandler) receiptHandlers = new ConcurrentHashMap<>(4);

	/* Whether the client is willfully closing the connection */
	private bool closing = false;


	/**
	 * Create a new session.
	 * @param sessionHandler the application handler for the session
	 * @param connectHeaders headers for the STOMP CONNECT frame
	 */
	public DefaultStompSession(StompSessionHandler sessionHandler, StompHeaders connectHeaders) {
		assert(sessionHandler, "StompSessionHandler must not be null");
		assert(connectHeaders, "StompHeaders must not be null");
		this.sessionId = idGenerator.generateId().toString();
		this.sessionHandler = sessionHandler;
		this.connectHeaders = connectHeaders;
	}


	override
	public string getSessionId() {
		return this.sessionId;
	}

	/**
	 * Return the configured session handler.
	 */
	public StompSessionHandler getSessionHandler() {
		return this.sessionHandler;
	}

	override
	public ListenableFuture!(StompSession) getSessionFuture() {
		return this.sessionFuture;
	}

	/**
	 * Set the {@link MessageConverter} to use to convert the payload of incoming
	 * and outgoing messages to and from {@code byte[]} based on object type, or
	 * expected object type, and the "content-type" header.
	 * <p>By default, {@link SimpleMessageConverter} is configured.
	 * @param messageConverter the message converter to use
	 */
	public void setMessageConverter(MessageConverter messageConverter) {
		assert(messageConverter, "MessageConverter must not be null");
		this.converter = messageConverter;
	}

	/**
	 * Return the configured {@link MessageConverter}.
	 */
	public MessageConverter getMessageConverter() {
		return this.converter;
	}

	/**
	 * Configure the TaskScheduler to use for receipt tracking.
	 */
	public void setTaskScheduler(TaskScheduler taskScheduler) {
		this.taskScheduler = taskScheduler;
	}

	/**
	 * Return the configured TaskScheduler to use for receipt tracking.
	 */
	
	public TaskScheduler getTaskScheduler() {
		return this.taskScheduler;
	}

	/**
	 * Configure the time in milliseconds before a receipt expires.
	 * <p>By default set to 15,000 (15 seconds).
	 */
	public void setReceiptTimeLimit(long receiptTimeLimit) {
		assert(receiptTimeLimit > 0, "Receipt time limit must be larger than zero");
		this.receiptTimeLimit = receiptTimeLimit;
	}

	/**
	 * Return the configured time limit before a receipt expires.
	 */
	public long getReceiptTimeLimit() {
		return this.receiptTimeLimit;
	}

	override
	public void setAutoReceipt( autoReceiptEnabled) {
		this.autoReceiptEnabled = autoReceiptEnabled;
	}

	/**
	 * Whether receipt headers should be automatically added.
	 */
	bool isAutoReceiptEnabled() {
		return this.autoReceiptEnabled;
	}


	override
	bool isConnected() {
		return (this.connection !is null);
	}

	override
	public Receiptable send(string destination, Object payload) {
		StompHeaders headers = new StompHeaders();
		headers.setDestination(destination);
		return send(headers, payload);
	}

	override
	public Receiptable send(StompHeaders headers, Object payload) {
		Assert.hasText(headers.getDestination(), "Destination header is required");

		string receiptId = checkOrAddReceipt(headers);
		Receiptable receiptable = new ReceiptHandler(receiptId);

		StompHeaderAccessor accessor = createHeaderAccessor(StompCommand.SEND);
		accessor.addNativeHeaders(headers);
		Message!(byte[]) message = createMessage(accessor, payload);
		execute(message);

		return receiptable;
	}

	
	private string checkOrAddReceipt(StompHeaders headers) {
		string receiptId = headers.getReceipt();
		if (isAutoReceiptEnabled() && receiptId is null) {
			receiptId = string.valueOf(DefaultStompSession.this.receiptIndex.getAndIncrement());
			headers.setReceipt(receiptId);
		}
		return receiptId;
	}

	private StompHeaderAccessor createHeaderAccessor(StompCommand command) {
		StompHeaderAccessor accessor = StompHeaderAccessor.create(command);
		accessor.setSessionId(this.sessionId);
		accessor.setLeaveMutable(true);
		return accessor;
	}

	
	private Message!(byte[]) createMessage(StompHeaderAccessor accessor, Object payload) {
		accessor.updateSimpMessageHeadersFromStompHeaders();
		Message!(byte[]) message;
		if (payload is null) {
			message = MessageBuilder.createMessage(EMPTY_PAYLOAD, accessor.getMessageHeaders());
		}
		else if (payload instanceof byte[]) {
			message = MessageBuilder.createMessage((byte[]) payload, accessor.getMessageHeaders());
		}
		else {
			message = (Message!(byte[])) getMessageConverter().toMessage(payload, accessor.getMessageHeaders());
			accessor.updateStompHeadersFromSimpMessageHeaders();
			if (message is null) {
				throw new MessageConversionException("Unable to convert payload with type='" ~
						payload.getClass().getName() ~ "', contentType='" ~ accessor.getContentType() +
						"', converter=[" ~ getMessageConverter() ~ "]");
			}
		}
		return message;
	}

	private void execute(Message!(byte[]) message) {
		version(HUNT_DEBUG) {
			StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
			if (accessor !is null) {
				trace("Sending " ~ accessor.getDetailedLogMessage(message.getPayload()));
			}
		}
		TcpConnection!(byte[]) conn = this.connection;
		Assert.state(conn !is null, "Connection closed");
		try {
			conn.send(message).get();
		}
		catch (ExecutionException ex) {
			throw new MessageDeliveryException(message, ex.getCause());
		}
		catch (Throwable ex) {
			throw new MessageDeliveryException(message, ex);
		}
	}

	override
	public Subscription subscribe(string destination, StompFrameHandler handler) {
		StompHeaders headers = new StompHeaders();
		headers.setDestination(destination);
		return subscribe(headers, handler);
	}

	override
	public Subscription subscribe(StompHeaders headers, StompFrameHandler handler) {
		Assert.hasText(headers.getDestination(), "Destination header is required");
		assert(handler, "StompFrameHandler must not be null");

		string subscriptionId = headers.getId();
		if (!StringUtils.hasText(subscriptionId)) {
			subscriptionId = string.valueOf(DefaultStompSession.this.subscriptionIndex.getAndIncrement());
			headers.setId(subscriptionId);
		}
		checkOrAddReceipt(headers);
		Subscription subscription = new DefaultSubscription(headers, handler);

		StompHeaderAccessor accessor = createHeaderAccessor(StompCommand.SUBSCRIBE);
		accessor.addNativeHeaders(headers);
		Message!(byte[]) message = createMessage(accessor, EMPTY_PAYLOAD);
		execute(message);

		return subscription;
	}

	override
	public Receiptable acknowledge(string messageId,  consumed) {
		StompHeaders headers = new StompHeaders();
		if ("1.1".equals(this.version)) {
			headers.setMessageId(messageId);
		}
		else {
			headers.setId(messageId);
		}
		return acknowledge(headers, consumed);
	}

	override
	public Receiptable acknowledge(StompHeaders headers,  consumed) {
		string receiptId = checkOrAddReceipt(headers);
		Receiptable receiptable = new ReceiptHandler(receiptId);

		StompCommand command = (consumed ? StompCommand.ACK : StompCommand.NACK);
		StompHeaderAccessor accessor = createHeaderAccessor(command);
		accessor.addNativeHeaders(headers);
		Message!(byte[]) message = createMessage(accessor, null);
		execute(message);

		return receiptable;
	}

	private void unsubscribe(string id, StompHeaders headers) {
		StompHeaderAccessor accessor = createHeaderAccessor(StompCommand.UNSUBSCRIBE);
		if (headers !is null) {
			accessor.addNativeHeaders(headers);
		}
		accessor.setSubscriptionId(id);
		Message!(byte[]) message = createMessage(accessor, EMPTY_PAYLOAD);
		execute(message);
	}

	override
	public void disconnect() {
		this.closing = true;
		try {
			StompHeaderAccessor accessor = createHeaderAccessor(StompCommand.DISCONNECT);
			Message!(byte[]) message = createMessage(accessor, EMPTY_PAYLOAD);
			execute(message);
		}
		finally {
			resetConnection();
		}
	}


	// TcpConnectionHandler

	override
	public void afterConnected(TcpConnection!(byte[]) connection) {
		this.connection = connection;
		version(HUNT_DEBUG) {
			trace("Connection established in session id=" ~ this.sessionId);
		}
		StompHeaderAccessor accessor = createHeaderAccessor(StompCommand.CONNECT);
		accessor.addNativeHeaders(this.connectHeaders);
		if (this.connectHeaders.getAcceptVersion() is null) {
			accessor.setAcceptVersion("1.1,1.2");
		}
		Message!(byte[]) message = createMessage(accessor, EMPTY_PAYLOAD);
		execute(message);
	}

	override
	public void afterConnectFailure(Throwable ex) {
		version(HUNT_DEBUG) {
			trace("Failed to connect session id=" ~ this.sessionId, ex);
		}
		this.sessionFuture.setException(ex);
		this.sessionHandler.handleTransportError(this, ex);
	}

	override
	public void handleMessage(Message!(byte[]) message) {
		StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
		Assert.state(accessor !is null, "No StompHeaderAccessor");

		accessor.setSessionId(this.sessionId);
		StompCommand command = accessor.getCommand();
		Map!(string, List!(string)) nativeHeaders = accessor.getNativeHeaders();
		StompHeaders headers = StompHeaders.readOnlyStompHeaders(nativeHeaders);
		 isHeartbeat = accessor.isHeartbeat();
		version(HUNT_DEBUG) {
			trace("Received " ~ accessor.getDetailedLogMessage(message.getPayload()));
		}

		try {
			if (StompCommand.MESSAGE.equals(command)) {
				DefaultSubscription subscription = this.subscriptions.get(headers.getSubscription());
				if (subscription !is null) {
					invokeHandler(subscription.getHandler(), message, headers);
				}
				else version(HUNT_DEBUG) {
					trace("No handler for: " ~ accessor.getDetailedLogMessage(message.getPayload()) +
							". Perhaps just unsubscribed?");
				}
			}
			else {
				if (StompCommand.RECEIPT.equals(command)) {
					string receiptId = headers.getReceiptId();
					ReceiptHandler handler = this.receiptHandlers.get(receiptId);
					if (handler !is null) {
						handler.handleReceiptReceived();
					}
					else version(HUNT_DEBUG) {
						trace("No matching receipt: " ~ accessor.getDetailedLogMessage(message.getPayload()));
					}
				}
				else if (StompCommand.CONNECTED.equals(command)) {
					initHeartbeatTasks(headers);
					this.version = headers.getFirst("version");
					this.sessionFuture.set(this);
					this.sessionHandler.afterConnected(this, headers);
				}
				else if (StompCommand.ERROR.equals(command)) {
					invokeHandler(this.sessionHandler, message, headers);
				}
				else if (!isHeartbeat && logger.isTraceEnabled()) {
					trace("Message not handled.");
				}
			}
		}
		catch (Throwable ex) {
			this.sessionHandler.handleException(this, command, headers, message.getPayload(), ex);
		}
	}

	private void invokeHandler(StompFrameHandler handler, Message!(byte[]) message, StompHeaders headers) {
		if (message.getPayload().length == 0) {
			handler.handleFrame(headers, null);
			return;
		}
		Type payloadType = handler.getPayloadType(headers);
		Class<?> resolvedType = ResolvableType.forType(payloadType).resolve();
		if (resolvedType is null) {
			throw new MessageConversionException("Unresolvable payload type [" ~ payloadType +
					"] from handler type [" ~ handler.getClass() ~ "]");
		}
		Object object = getMessageConverter().fromMessage(message, resolvedType);
		if (object is null) {
			throw new MessageConversionException("No suitable converter for payload type [" ~ payloadType +
					"] from handler type [" ~ handler.getClass() ~ "]");
		}
		handler.handleFrame(headers, object);
	}

	private void initHeartbeatTasks(StompHeaders connectedHeaders) {
		long[] connect = this.connectHeaders.getHeartbeat();
		long[] connected = connectedHeaders.getHeartbeat();
		if (connect is null || connected is null) {
			return;
		}
		TcpConnection!(byte[]) con = this.connection;
		Assert.state(con !is null, "No TcpConnection available");
		if (connect[0] > 0 && connected[1] > 0) {
			long interval = Math.max(connect[0],  connected[1]);
			con.onWriteInactivity(new WriteInactivityTask(), interval);
		}
		if (connect[1] > 0 && connected[0] > 0) {
			long interval = Math.max(connect[1], connected[0]) * HEARTBEAT_MULTIPLIER;
			con.onReadInactivity(new ReadInactivityTask(), interval);
		}
	}

	override
	public void handleFailure(Throwable ex) {
		try {
			this.sessionFuture.setException(ex);  // no-op if already set
			this.sessionHandler.handleTransportError(this, ex);
		}
		catch (Throwable ex2) {
			version(HUNT_DEBUG) {
				trace("Uncaught failure while handling transport failure", ex2);
			}
		}
	}

	override
	public void afterConnectionClosed() {
		version(HUNT_DEBUG) {
			trace("Connection closed in session id=" ~ this.sessionId);
		}
		if (!this.closing) {
			resetConnection();
			handleFailure(new ConnectionLostException("Connection closed"));
		}
	}

	private void resetConnection() {
		TcpConnection<?> conn = this.connection;
		this.connection = null;
		if (conn !is null) {
			try {
				conn.close();
			}
			catch (Throwable ex) {
				// ignore
			}
		}
	}


	private class ReceiptHandler implements Receiptable {

		
		private final string receiptId;

		private final List!(Runnable) receiptCallbacks = new ArrayList<>(2);

		private final List!(Runnable) receiptLostCallbacks = new ArrayList<>(2);

		
		private ScheduledFuture<?> future;

		
		private Boolean result;

		public ReceiptHandler(string receiptId) {
			this.receiptId = receiptId;
			if (receiptId !is null) {
				initReceiptHandling();
			}
		}

		private void initReceiptHandling() {
			assert(getTaskScheduler(), "To track receipts, a TaskScheduler must be configured");
			DefaultStompSession.this.receiptHandlers.put(this.receiptId, this);
			Date startTime = new Date(System.currentTimeMillis() + getReceiptTimeLimit());
			this.future = getTaskScheduler().schedule(this::handleReceiptNotReceived, startTime);
		}

		override
		
		public string getReceiptId() {
			return this.receiptId;
		}

		override
		public void addReceiptTask(Runnable task) {
			addTask(task, true);
		}

		override
		public void addReceiptLostTask(Runnable task) {
			addTask(task, false);
		}

		private void addTask(Runnable task,  successTask) {
			assert(this.receiptId,
					"To track receipts, set autoReceiptEnabled=true or add 'receiptId' header");
			synchronized (this) {
				if (this.result !is null && this.result == successTask) {
					invoke(Collections.singletonList(task));
				}
				else {
					if (successTask) {
						this.receiptCallbacks.add(task);
					}
					else {
						this.receiptLostCallbacks.add(task);
					}
				}
			}
		}

		private void invoke(List!(Runnable) callbacks) {
			for (Runnable runnable : callbacks) {
				try {
					runnable.run();
				}
				catch (Throwable ex) {
					// ignore
				}
			}
		}

		public void handleReceiptReceived() {
			handleInternal(true);
		}

		public void handleReceiptNotReceived() {
			handleInternal(false);
		}

		private void handleInternal( result) {
			synchronized (this) {
				if (this.result !is null) {
					return;
				}
				this.result = result;
				invoke(result ? this.receiptCallbacks : this.receiptLostCallbacks);
				DefaultStompSession.this.receiptHandlers.remove(this.receiptId);
				if (this.future !is null) {
					this.future.cancel(true);
				}
			}
		}
	}


	private class DefaultSubscription extends ReceiptHandler implements Subscription {

		private final StompHeaders headers;

		private final StompFrameHandler handler;

		public DefaultSubscription(StompHeaders headers, StompFrameHandler handler) {
			super(headers.getReceipt());
			assert(headers.getDestination(), "Destination must not be null");
			assert(handler, "StompFrameHandler must not be null");
			this.headers = headers;
			this.handler = handler;
			DefaultStompSession.this.subscriptions.put(headers.getId(), this);
		}

		override
		
		public string getSubscriptionId() {
			return this.headers.getId();
		}

		override
		public StompHeaders getSubscriptionHeaders() {
			return this.headers;
		}

		public StompFrameHandler getHandler() {
			return this.handler;
		}

		override
		public void unsubscribe() {
			unsubscribe(null);
		}

		override
		public void unsubscribe(StompHeaders headers) {
			string id = this.headers.getId();
			if (id !is null) {
				DefaultStompSession.this.subscriptions.remove(id);
				DefaultStompSession.this.unsubscribe(id, headers);
			}
		}

		override
		public string toString() {
			return "Subscription [id=" ~ getSubscriptionId() +
					", destination='" ~ this.headers.getDestination() +
					"', receiptId='" ~ getReceiptId() ~ "', handler=" ~ getHandler() ~ "]";
		}
	}


	private class WriteInactivityTask implements Runnable {

		override
		public void run() {
			TcpConnection!(byte[]) conn = connection;
			if (conn !is null) {
				conn.send(HEARTBEAT).addCallback(
						new ListenableFutureCallback!(Void)() {
							public void onSuccess(Void result) {
							}
							public void onFailure(Throwable ex) {
								handleFailure(ex);
							}
						});
			}
		}
	}


	private class ReadInactivityTask implements Runnable {

		override
		public void run() {
			closing = true;
			string error = "Server has gone quiet. Closing connection in session id=" ~ sessionId ~ ".";
			version(HUNT_DEBUG) {
				trace(error);
			}
			resetConnection();
			handleFailure(new IllegalStateException(error));
		}
	}

}
