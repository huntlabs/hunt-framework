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

module hunt.framework.messaging.simp.SimpMessagingTemplate;

import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
import hunt.framework.messaging.simp.SimpMessageSendingOperations;
import hunt.framework.messaging.simp.SimpMessageType;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageChannel;
import hunt.framework.messaging.MessageHeaders;
import hunt.framework.messaging.MessagingException;
import hunt.framework.messaging.core.AbstractMessageSendingTemplate;
import hunt.framework.messaging.core.MessagePostProcessor;
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;

import hunt.framework.messaging.support.NativeMessageHeaderAccessor;
// import hunt.framework.util.StringUtils;

import hunt.container.Map;
import hunt.logging;
import std.array;
import std.conv;
import std.string;

/**
 * An implementation of
 * {@link hunt.framework.messaging.simp.SimpMessageSendingOperations}.
 *
 * <p>Also provides methods for sending messages to a user. See
 * {@link hunt.framework.messaging.simp.user.UserDestinationResolver
 * UserDestinationResolver}
 * for more on user destinations.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class SimpMessagingTemplate : AbstractMessageSendingTemplate!(string), SimpMessageSendingOperations { 

	private MessageChannel messageChannel;

	private string destinationPrefix = "/user/";

	private long sendTimeout = -1;
	
	private MessageHeaderInitializer headerInitializer;


	/**
	 * Create a new {@link SimpMessagingTemplate} instance.
	 * @param messageChannel the message channel (never {@code null})
	 */
	this(MessageChannel messageChannel) {
		assert(messageChannel, "MessageChannel must not be null");
		this.messageChannel = messageChannel;
	}


	/**
	 * Return the configured message channel.
	 */
	MessageChannel getMessageChannel() {
		return this.messageChannel;
	}

	/**
	 * Configure the prefix to use for destinations targeting a specific user.
	 * <p>The default value is "/user/".
	 * @see hunt.framework.messaging.simp.user.UserDestinationMessageHandler
	 */
	void setUserDestinationPrefix(string prefix) {
		assert(!prefix.empty, "User destination prefix must not be empty");
		this.destinationPrefix = (prefix.endsWith("/") ? prefix : prefix ~ "/");

	}

	/**
	 * Return the configured user destination prefix.
	 */
	string getUserDestinationPrefix() {
		return this.destinationPrefix;
	}

	/**
	 * Specify the timeout value to use for send operations (in milliseconds).
	 */
	void setSendTimeout(long sendTimeout) {
		this.sendTimeout = sendTimeout;
	}

	/**
	 * Return the configured send timeout (in milliseconds).
	 */
	long getSendTimeout() {
		return this.sendTimeout;
	}

	/**
	 * Configure a {@link MessageHeaderInitializer} to apply to the headers of all
	 * messages created through the {@code SimpMessagingTemplate}.
	 * <p>By default, this property is not set.
	 */
	void setHeaderInitializer(MessageHeaderInitializer headerInitializer) {
		this.headerInitializer = headerInitializer;
	}

	/**
	 * Return the configured header initializer.
	 */
	
	MessageHeaderInitializer getHeaderInitializer() {
		return this.headerInitializer;
	}


	/**
	 * If the headers of the given message already contain a
	 * {@link hunt.framework.messaging.simp.SimpMessageHeaderAccessor#DESTINATION_HEADER
	 * SimpMessageHeaderAccessor#DESTINATION_HEADER} then the message is sent without
	 * further changes.
	 * <p>If a destination header is not already present ,the message is sent
	 * to the configured {@link #setDefaultDestination(Object) defaultDestination}
	 * or an exception an {@code IllegalStateException} is raised if that isn't
	 * configured.
	 * @param message the message to send (never {@code null})
	 */
	override
	void send(MessageBase message) {
		assert(message !is null, "Message is required");
		string destination = SimpMessageHeaderAccessor.getDestination(message.getHeaders());
		if (destination !is null) {
			sendInternal(message);
			return;
		}
		doSend(getRequiredDefaultDestination(), message);
	}

	override
	protected void doSend(string destination, MessageBase message) {
		assert(destination, "Destination must not be null");

		SimpMessageHeaderAccessor simpAccessor =
				MessageHeaderAccessor.getAccessor!SimpMessageHeaderAccessor(message);

		if (simpAccessor !is null) {
			if (simpAccessor.isMutable()) {
				simpAccessor.setDestination(destination);
				simpAccessor.setMessageTypeIfNotSet(SimpMessageType.MESSAGE);
				simpAccessor.setImmutable();
				sendInternal(message);
				return;
			}
			else {
				// Try and keep the original accessor type
				simpAccessor = cast(SimpMessageHeaderAccessor) MessageHeaderAccessor.getMutableAccessor(message);
				initHeaders(simpAccessor);
			}
		}
		else {
			simpAccessor = SimpMessageHeaderAccessor.wrap(message);
			initHeaders(simpAccessor);
		}

		simpAccessor.setDestination(destination);
		simpAccessor.setMessageTypeIfNotSet(SimpMessageType.MESSAGE);
        Message!(string) m = cast(Message!(string))message;
        if(m is null) {
            warning("Can't handle messsage: ", typeid(cast(Object)message));
        } else {
            message = MessageHelper.createMessage(m.getPayload(), simpAccessor.getMessageHeaders());
            sendInternal(message);
        }
	}

	private void sendInternal(MessageBase message) {
		string destination = SimpMessageHeaderAccessor.getDestination(message.getHeaders());
		assert(destination, "Destination header required");

		long timeout = this.sendTimeout;
		bool sent = (timeout >= 0 ? this.messageChannel.send(message, timeout) : this.messageChannel.send(message));

		if (!sent) {
			throw new MessageDeliveryException(message,
					"Failed to send message to destination '" ~ destination ~ 
                    "' within timeout: " ~ timeout.to!string());
		}
	}

	private void initHeaders(SimpMessageHeaderAccessor simpAccessor) {
		if (getHeaderInitializer() !is null) {
			getHeaderInitializer().initHeaders(simpAccessor);
		}
	}


	override
	void convertAndSendToUser(string user, string destination, Object payload) {
		convertAndSendToUser(user, destination, payload, cast(MessagePostProcessor) null);
	}

	override
	void convertAndSendToUser(string user, string destination, Object payload,
			Map!(string, Object) headers) {

		convertAndSendToUser(user, destination, payload, headers, null);
	}

	override
	void convertAndSendToUser(string user, string destination, Object payload,
			MessagePostProcessor postProcessor) {

		convertAndSendToUser(user, destination, payload, null, postProcessor);
	}

	override
	void convertAndSendToUser(string user, string destination, Object payload,
			Map!(string, Object) headers, MessagePostProcessor postProcessor) {

		assert(user, "User must not be null");
		user = user.replace("/", "%2F");
		destination = destination.startsWith("/") ? destination : "/" ~ destination;
		super.convertAndSend(this.destinationPrefix ~ user ~ destination, payload, headers, postProcessor);
	}


	/**
	 * Creates a new map and puts the given headers under the key
	 * {@link NativeMessageHeaderAccessor#NATIVE_HEADERS NATIVE_HEADERS NATIVE_HEADERS NATIVE_HEADERS}.
	 * effectively treats the input header map as headers to be sent out to the
	 * destination.
	 * <p>However if the given headers already contain the key
	 * {@code NATIVE_HEADERS NATIVE_HEADERS} then the same headers instance is
	 * returned without changes.
	 * <p>Also if the given headers were prepared and obtained with
	 * {@link SimpMessageHeaderAccessor#getMessageHeaders()} then the same headers
	 * instance is also returned without changes.
	 */
	override
	protected Map!(string, Object) processHeadersToSend(Map!(string, Object) headers) {
		if (headers is null) {
			SimpMessageHeaderAccessor headerAccessor = SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);
			initHeaders(headerAccessor);
			headerAccessor.setLeaveMutable(true);
			return headerAccessor.getMessageHeaders();
		}

		if (headers.containsKey(NativeMessageHeaderAccessor.NATIVE_HEADERS)) {
			return headers;
		}

        MessageHeaders mheaders = cast(MessageHeaders) headers;
		if (mheaders !is null) {
			SimpMessageHeaderAccessor accessor =
					MessageHeaderAccessor.getAccessor!(SimpMessageHeaderAccessor)(mheaders);
			if (accessor !is null) {
				return headers;
			}
		}

		SimpMessageHeaderAccessor headerAccessor = SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);
		initHeaders(headerAccessor);
        foreach(string key, Object value; headers) {
            headerAccessor.setNativeHeader(key, (value !is null ? value.toString() : null));
        }
		return headerAccessor.getMessageHeaders();
	}

}
