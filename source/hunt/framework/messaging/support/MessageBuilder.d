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

module hunt.framework.messaging.support.MessageBuilder;

import hunt.framework.messaging.support.ErrorMessage;
import hunt.framework.messaging.support.GenericMessage;
import hunt.framework.messaging.support.MessageHeaderAccessor;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageChannel;
import hunt.framework.messaging.MessageHeaders;

import hunt.container.Map;

/**
 * A builder for creating a {@link GenericMessage}
 * (or {@link ErrorMessage} if the payload is of type {@link Throwable}).
 *
 * @author Arjen Poutsma
 * @author Mark Fisher
 * @author Rossen Stoyanchev
 * @since 4.0
 * @param (T) the message payload type
 * @see GenericMessage
 * @see ErrorMessage
 */
final class MessageBuilder(T) {

	private T payload;
	
	private Message!(T) originalMessage;

	private MessageHeaderAccessor headerAccessor;


	private this(Message!(T) originalMessage) {
		assert(originalMessage, "Message must not be null");
		this.payload = originalMessage.getPayload();
		this.originalMessage = originalMessage;
		this.headerAccessor = new MessageHeaderAccessor(originalMessage);
	}

	private this(T payload, MessageHeaderAccessor accessor) {
		// assert(payload, "Payload must not be null");
		assert(accessor, "MessageHeaderAccessor must not be null");
		this.payload = payload;
		this.originalMessage = null;
		this.headerAccessor = accessor;
	}


	/**
	 * Set the message headers to use by providing a {@code MessageHeaderAccessor}.
	 * @param accessor the headers to use
	 */
	MessageBuilder!(T) setHeaders(MessageHeaderAccessor accessor) {
		assert(accessor, "MessageHeaderAccessor must not be null");
		this.headerAccessor = accessor;
		return this;
	}

	/**
	 * Set the value for the given header name. If the provided value is {@code null},
	 * the header will be removed.
	 */
	MessageBuilder!(T) setHeader(string headerName, Object headerValue) {
		this.headerAccessor.setHeader(headerName, headerValue);
		return this;
	}

	/**
	 * Set the value for the given header name only if the header name is not already
	 * associated with a value.
	 */
	MessageBuilder!(T) setHeaderIfAbsent(string headerName, Object headerValue) {
		this.headerAccessor.setHeaderIfAbsent(headerName, headerValue);
		return this;
	}

	/**
	 * Removes all headers provided via array of 'headerPatterns'. As the name suggests
	 * the array may contain simple matching patterns for header names. Supported pattern
	 * styles are: "xxx*", "*xxx", "*xxx*" and "xxx*yyy".
	 */
	MessageBuilder!(T) removeHeaders(string[] headerPatterns... ) {
		this.headerAccessor.removeHeaders(headerPatterns.dup);
		return this;
	}
	/**
	 * Remove the value for the given header name.
	 */
	MessageBuilder!(T) removeHeader(string headerName) {
		this.headerAccessor.removeHeader(headerName);
		return this;
	}

	/**
	 * Copy the name-value pairs from the provided Map. This operation will overwrite any
	 * existing values. Use { {@link #copyHeadersIfAbsent(Map)} to avoid overwriting
	 * values. Note that the 'id' and 'timestamp' header values will never be overwritten.
	 */
	MessageBuilder!(T) copyHeaders(Map!(string, Object) headersToCopy) {
		this.headerAccessor.copyHeaders(headersToCopy);
		return this;
	}

	/**
	 * Copy the name-value pairs from the provided Map. This operation will <em>not</em>
	 * overwrite any existing values.
	 */
	MessageBuilder!(T) copyHeadersIfAbsent(Map!(string, Object) headersToCopy) {
		this.headerAccessor.copyHeadersIfAbsent(headersToCopy);
		return this;
	}

	MessageBuilder!(T) setReplyChannel(MessageChannel replyChannel) {
		this.headerAccessor.setReplyChannel(replyChannel);
		return this;
	}

	MessageBuilder!(T) setReplyChannelName(string replyChannelName) {
		this.headerAccessor.setReplyChannelName(replyChannelName);
		return this;
	}

	MessageBuilder!(T) setErrorChannel(MessageChannel errorChannel) {
		this.headerAccessor.setErrorChannel(errorChannel);
		return this;
	}

	MessageBuilder!(T) setErrorChannelName(string errorChannelName) {
		this.headerAccessor.setErrorChannelName(errorChannelName);
		return this;
	}

	
	Message!(T) build() {
		if (this.originalMessage !is null && !this.headerAccessor.isModified()) {
			return this.originalMessage;
		}
		MessageHeaders headersToUse = this.headerAccessor.toMessageHeaders();
		static if(is(T == class) || is(T == interface)) {
			Throwable th = cast(Throwable) this.payload;
			if (th !is null) {
				return cast(Message!(T)) new ErrorMessage(th, headersToUse);
			} 
		} 
		
		return new GenericMessage!(T)(this.payload, headersToUse);
	}

}


/**
*/
class MessageHelper {

	/**
	 * Create a builder for a new {@link Message} instance pre-populated with all of the
	 * headers copied from the provided message. The payload of the provided Message will
	 * also be used as the payload for the new message.
	 * @param message the Message from which the payload and all headers will be copied
	 */
	static MessageBuilder!(T) fromMessage(T)(Message!(T) message) {
		return new MessageBuilder!(T)(message);
	}

	/**
	 * Create a new builder for a message with the given payload.
	 * @param payload the payload
	 */
	static MessageBuilder!(T) withPayload(T)(T payload) {
		return new MessageBuilder!(T)(payload, new MessageHeaderAccessor());
	}

	/**
	 * A shortcut factory method for creating a message with the given payload
	 * and {@code MessageHeaders}.
	 * <p><strong>Note:</strong> the given {@code MessageHeaders} instance is used
	 * directly in the new message, i.e. it is not copied.
	 * @param payload the payload to use (never {@code null})
	 * @param messageHeaders the headers to use (never {@code null})
	 * @return the created message
	 * @since 4.1
	 */
	static MessageBase createMessage(T)(Object payload, MessageHeaders messageHeaders) 
		if(is(T == class) || is(T == interface)) {
		// assert(payload, "Payload must not be null");
		assert(messageHeaders, "MessageHeaders must not be null");
		Throwable th = cast(Throwable) payload;
		if (th !is null) 
			return new ErrorMessage(th, messageHeaders);
		return new GenericMessage!(T)(payload, messageHeaders);
	}

	static Message!(T) createMessage(T)(T payload, MessageHeaders messageHeaders) 
		if(!is(T == class) && !is(T == interface)) {
		// assert(payload, "Payload must not be null");
		assert(messageHeaders, "MessageHeaders must not be null");

		return new GenericMessage!(T)(payload, messageHeaders);
	}
}