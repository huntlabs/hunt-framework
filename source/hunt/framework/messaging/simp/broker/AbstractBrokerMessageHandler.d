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

module hunt.framework.messaging.simp.broker.AbstractBrokerMessageHandler;

import hunt.framework.messaging.simp.broker.OrderedMessageSender;

import hunt.lang.common;
import hunt.container;
import hunt.logging;

import hunt.framework.context.ApplicationEvent;
// import hunt.framework.context.ApplicationEventPublisherAware;
// import hunt.framework.context.SmartLifecycle;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageChannel;
import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
import hunt.framework.messaging.simp.SimpMessageType;
import hunt.framework.messaging.support.ChannelInterceptor;
import hunt.framework.messaging.support.InterceptableChannel;


/**
 * Abstract base class for a {@link MessageHandler} that broker messages to
 * registered subscribers.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
abstract class AbstractBrokerMessageHandler
		: MessageHandler { // , ApplicationEventPublisherAware, SmartLifecycle

	private SubscribableChannel clientInboundChannel;

	private MessageChannel clientOutboundChannel;

	private SubscribableChannel brokerChannel;

	private string[] destinationPrefixes;

	private bool preservePublishOrder = false;
	
	private ApplicationEventPublisher eventPublisher;

	private bool brokerAvailable = false;

	private BrokerAvailabilityEvent availableEvent;

	private BrokerAvailabilityEvent notAvailableEvent;

	private bool autoStartup = true;

	private bool running = false;

	private Object lifecycleMonitor;

	private ChannelInterceptor unsentDisconnectInterceptor;


	private void initilize() {
		availableEvent = new BrokerAvailabilityEvent(true, this);
		notAvailableEvent = new BrokerAvailabilityEvent(false, this);
		lifecycleMonitor = new Object();
		unsentDisconnectInterceptor = new UnsentDisconnectChannelInterceptor();
	}

	/**
	 * Constructor with no destination prefixes (matches all destinations).
	 * @param inboundChannel the channel for receiving messages from clients (e.g. WebSocket clients)
	 * @param outboundChannel the channel for sending messages to clients (e.g. WebSocket clients)
	 * @param brokerChannel the channel for the application to send messages to the broker
	 */
	this(SubscribableChannel inboundChannel, MessageChannel outboundChannel,
			SubscribableChannel brokerChannel) {
		this(inboundChannel, outboundChannel, brokerChannel, []);
	}

	/**
	 * Constructor with destination prefixes to match to destinations of messages.
	 * @param inboundChannel the channel for receiving messages from clients (e.g. WebSocket clients)
	 * @param outboundChannel the channel for sending messages to clients (e.g. WebSocket clients)
	 * @param brokerChannel the channel for the application to send messages to the broker
	 * @param destinationPrefixes prefixes to use to filter out messages
	 */
	this(SubscribableChannel inboundChannel, MessageChannel outboundChannel,
			SubscribableChannel brokerChannel, string[] destinationPrefixes) {

		assert(inboundChannel, "'inboundChannel' must not be null");
		assert(outboundChannel, "'outboundChannel' must not be null");
		assert(brokerChannel, "'brokerChannel' must not be null");
		
		initilize();
		this.clientInboundChannel = inboundChannel;
		this.clientOutboundChannel = outboundChannel;
		this.brokerChannel = brokerChannel;

		destinationPrefixes = (destinationPrefixes !is null ? destinationPrefixes : []);
		this.destinationPrefixes = Collections.unmodifiableCollection(destinationPrefixes);
	}


	SubscribableChannel getClientInboundChannel() {
		return this.clientInboundChannel;
	}

	MessageChannel getClientOutboundChannel() {
		return this.clientOutboundChannel;
	}

	SubscribableChannel getBrokerChannel() {
		return this.brokerChannel;
	}

	string[] getDestinationPrefixes() {
		return this.destinationPrefixes;
	}

	/**
	 * Whether the client must receive messages in the order of publication.
	 * <p>By default messages sent to the {@code "clientOutboundChannel"} may
	 * not be processed in the same order because the channel is backed by a
	 * ThreadPoolExecutor that in turn does not guarantee processing in order.
	 * <p>When this flag is set to {@code true} messages within the same session
	 * will be sent to the {@code "clientOutboundChannel"} one at a time in
	 * order to preserve the order of publication. Enable this only if needed
	 * since there is some performance overhead to keep messages in order.
	 * @param preservePublishOrder whether to publish in order
	 * @since 5.1
	 */
	void setPreservePublishOrder( preservePublishOrder) {
		OrderedMessageSender.configureOutboundChannel(this.clientOutboundChannel, preservePublishOrder);
		this.preservePublishOrder = preservePublishOrder;
	}

	/**
	 * Whether to ensure messages are received in the order of publication.
	 * @since 5.1
	 */
	bool isPreservePublishOrder() {
		return this.preservePublishOrder;
	}

	override
	void setApplicationEventPublisher(ApplicationEventPublisher publisher) {
		this.eventPublisher = publisher;
	}

	
	ApplicationEventPublisher getApplicationEventPublisher() {
		return this.eventPublisher;
	}

	void setAutoStartup( autoStartup) {
		this.autoStartup = autoStartup;
	}

	override
	bool isAutoStartup() {
		return this.autoStartup;
	}


	override
	void start() {
		synchronized (this.lifecycleMonitor) {
			info("Starting...");
			this.clientInboundChannel.subscribe(this);
			this.brokerChannel.subscribe(this);
			InterceptableChannel channel = cast(InterceptableChannel) this.clientInboundChannel;
			if (channel !is null) {
				channel.addInterceptor(0, this.unsentDisconnectInterceptor);
			}
			startInternal();
			this.running = true;
			info("Started.");
		}
	}

	protected void startInternal() {
	}

	override
	void stop() {
		synchronized (this.lifecycleMonitor) {
			info("Stopping...");
			stopInternal();
			this.clientInboundChannel.unsubscribe(this);
			this.brokerChannel.unsubscribe(this);
			InterceptableChannel channel = cast(InterceptableChannel) this.clientInboundChannel;
			if (channel !is null) {
				channel.removeInterceptor(this.unsentDisconnectInterceptor);
			}
			this.running = false;
			info("Stopped.");
		}
	}

	protected void stopInternal() {
	}

	override
	final void stop(Runnable callback) {
		synchronized (this.lifecycleMonitor) {
			stop();
			callback.run();
		}
	}

	/**
	 * Check whether this message handler is currently running.
	 * <p>Note that even when this message handler is running the
	 * {@link #isBrokerAvailable()} flag may still independently alternate between
	 * being on and off depending on the concrete sub-class implementation.
	 */
	override
	final bool isRunning() {
		return this.running;
	}

	/**
	 * Whether the message broker is currently available and able to process messages.
	 * <p>Note that this is in addition to the {@link #isRunning()} flag, which
	 * indicates whether this message handler is running. In other words the message
	 * handler must first be running and then the {@code #isBrokerAvailable()} flag
	 * may still independently alternate between being on and off depending on the
	 * concrete sub-class implementation.
	 * <p>Application components may implement
	 * {@code hunt.framework.context.ApplicationListener&lt;BrokerAvailabilityEvent&gt;}
	 * to receive notifications when broker becomes available and unavailable.
	 */
	bool isBrokerAvailable() {
		return this.brokerAvailable;
	}


	override
	void handleMessage(MessageBase message) {
		if (!this.running) {
			version(HUNT_DEBUG) {
				trace(this ~ " not running yet. Ignoring " ~ message);
			}
			return;
		}
		handleMessageInternal(message);
	}

	protected abstract void handleMessageInternal(MessageBase message);


	protected bool checkDestinationPrefix(string destination) {
		if (destination is null || CollectionUtils.isEmpty(this.destinationPrefixes)) {
			return true;
		}
		foreach (string prefix ; this.destinationPrefixes) {
			if (destination.startsWith(prefix)) {
				return true;
			}
		}
		return false;
	}

	protected void publishBrokerAvailableEvent() {
		 shouldPublish = this.brokerAvailable.compareAndSet(false, true);
		if (this.eventPublisher !is null && shouldPublish) {
			version(HUNT_DEBUG) {
				info(this.availableEvent);
			}
			this.eventPublisher.publishEvent(this.availableEvent);
		}
	}

	protected void publishBrokerUnavailableEvent() {
		 shouldPublish = this.brokerAvailable.compareAndSet(true, false);
		if (this.eventPublisher !is null && shouldPublish) {
			version(HUNT_DEBUG) {
				info(this.notAvailableEvent);
			}
			this.eventPublisher.publishEvent(this.notAvailableEvent);
		}
	}

	/**
	 * Get the MessageChannel to use for sending messages to clients, possibly
	 * a per-session wrapper when {@code preservePublishOrder=true}.
	 * @since 5.1
	 */
	protected MessageChannel getClientOutboundChannelForSession(string sessionId) {
		return this.preservePublishOrder ?
				new OrderedMessageSender(getClientOutboundChannel(), logger) : getClientOutboundChannel();
	}


	/**
	 * Detect unsent DISCONNECT messages and process them anyway.
	 */
	private class UnsentDisconnectChannelInterceptor : ChannelInterceptor {

		override
		void afterSendCompletion(
				MessageBase message, MessageChannel channel,  sent, Exception ex) {

			if (!sent) {
				SimpMessageType messageType = SimpMessageHeaderAccessor.getMessageType(message.getHeaders());
				if (SimpMessageType.DISCONNECT.equals(messageType)) {
					trace("Detected unsent DISCONNECT message. Processing anyway.");
					handleMessage(message);
				}
			}
		}
	}

}
