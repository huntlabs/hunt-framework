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

module hunt.framework.messaging.core.AbstractMessageSendingTemplate;

import hunt.container.Map;
import hunt.logging;
import hunt.lang.exception;

import hunt.framework.messaging.converter.MessageConverter;
import hunt.framework.messaging.converter.SimpleMessageConverter;
import hunt.framework.messaging.converter.SmartMessageConverter;
import hunt.framework.messaging.core.MessagePostProcessor;
import hunt.framework.messaging.core.MessageSendingOperations;
import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;
import hunt.framework.messaging.MessagingException;


/**
 * Abstract base class for implementations of {@link MessageSendingOperations}.
 *
 * @author Mark Fisher
 * @author Rossen Stoyanchev
 * @author Stephane Nicoll
 * @since 4.0
 * @param (T) the destination type
 */
abstract class AbstractMessageSendingTemplate(T) : MessageSendingOperations!(T) {

	/**
	 * Name of the header that can be set to provide further information
	 * (e.g. a {@code MethodParameter} instance) about the origin of the
	 * payload, to be taken into account as a conversion hint.
	 * @since 4.2
	 */
	enum string CONVERSION_HINT_HEADER = "conversionHint";

	private T defaultDestination;

	private MessageConverter converter;

	this() {
		converter = new SimpleMessageConverter();
	}


	/**
	 * Configure the default destination to use in send methods that don't have
	 * a destination argument. If a default destination is not configured, send methods
	 * without a destination argument will raise an exception if invoked.
	 */
	void setDefaultDestination(T defaultDestination) {
		this.defaultDestination = defaultDestination;
	}

	/**
	 * Return the configured default destination.
	 */
	
	T getDefaultDestination() {
		return this.defaultDestination;
	}

	/**
	 * Set the {@link MessageConverter} to use in {@code convertAndSend} methods.
	 * <p>By default, {@link SimpleMessageConverter} is used.
	 * @param messageConverter the message converter to use
	 */
	void setMessageConverter(MessageConverter messageConverter) {
		assert(messageConverter, "MessageConverter must not be null");
		this.converter = messageConverter;
	}

	/**
	 * Return the configured {@link MessageConverter}.
	 */
	MessageConverter getMessageConverter() {
		return this.converter;
	}


	override
	void send(MessageBase message) {
		send(getRequiredDefaultDestination(), message);
	}

	protected final T getRequiredDefaultDestination() {
		assert(this.defaultDestination !is null, "No 'defaultDestination' configured");
		return this.defaultDestination;
	}

	override
	void send(T destination, MessageBase message) {
		doSend(destination, message);
	}

	protected abstract void doSend(T destination, MessageBase message);


	override
	void convertAndSend(Object payload) {
		convertAndSend(payload, null);
	}

	override
	void convertAndSend(T destination, Object payload) {
		convertAndSend(destination, payload, cast(Map!(string, Object)) null);
	}

	override
	void convertAndSend(T destination, Object payload, Map!(string, Object) headers) {

		convertAndSend(destination, payload, headers, null);
	}

	override
	void convertAndSend(Object payload, MessagePostProcessor postProcessor) {
		convertAndSend(getRequiredDefaultDestination(), payload, postProcessor);
	}

	override
	void convertAndSend(T destination, Object payload, MessagePostProcessor postProcessor) {
		convertAndSend(destination, payload, null, postProcessor);
	}

	override
	void convertAndSend(T destination, Object payload, Map!(string, Object) headers,
			MessagePostProcessor postProcessor) {

		MessageBase message = doConvert(payload, headers, postProcessor);
		send(destination, message);
	}

	/**
	 * Convert the given Object to serialized form, possibly using a
	 * {@link MessageConverter}, wrap it as a message with the given
	 * headers and apply the given post processor.
	 * @param payload the Object to use as payload
	 * @param headers headers for the message to send
	 * @param postProcessor the post processor to apply to the message
	 * @return the converted message
	 */
	protected Message!(T) doConvert(Object payload, Map!(string, Object) headers,
			MessagePostProcessor postProcessor) {

		MessageHeaders messageHeaders = null;

		Map!(string, Object) headersToUse = processHeadersToSend(headers);
		if (headersToUse !is null) {
			messageHeaders = cast(MessageHeaders) headersToUse;
			if (messageHeaders is null) {
				messageHeaders = new MessageHeaders(headersToUse);
			}
		}

		Object conversionHintObj = (headers !is null ? headers.get(CONVERSION_HINT_HEADER) : null);
		TypeInfo conversionHint = cast(TypeInfo)conversionHintObj;
		MessageConverter converter = getMessageConverter();

		version(HUNT_DEBUG) {
			if(conversionHint is null)
				warningf("conversionHintObj: %s", conversionHintObj);
			else
				tracef("conversionHint: %s", conversionHint);
			tracef("MessageConverter is: %s", typeid(cast(Object)converter));
		}

		SmartMessageConverter smc = cast(SmartMessageConverter) converter;
		MessageBase message;
		if(smc is null)
			message = converter.toMessage(payload, messageHeaders);
		else
			message = smc.toMessage(payload, messageHeaders, conversionHint);

		if (message is null) {
			version(HUNT_DEBUG) warning("message is null");
			string payloadType = typeid(payload).toString();
			Object contentType = (messageHeaders !is null ? messageHeaders.get(MessageHeaders.CONTENT_TYPE) : null);
			if(contentType is null) {
				throw new MessageConversionException("Unable to convert payload with type='null', converter=[" ~ 
						(cast(Object) getMessageConverter()).toString() ~ "]");
			} else {
				throw new MessageConversionException("Unable to convert payload with type='" ~ payloadType ~
						"', contentType='" ~ contentType.toString() ~ "', converter=[" ~ 
						(cast(Object) getMessageConverter()).toString() ~ "]");
			}
		}

		if (postProcessor !is null) {
			message = postProcessor.postProcessMessage(message);
		}
		Message!(T) r = cast(Message!(T)) message;
		if(r is null)
			warningf("Message conversion error, expected: %s, actual: %s", typeid(Message!(T)), typeid(message));
		return r;
	}

	/**
	 * Provides access to the map of input headers before a send operation.
	 * Subclasses can modify the headers and then return the same or a different map.
	 * <p>This default implementation in this class returns the input map.
	 * @param headers the headers to send (or {@code null} if none)
	 * @return the actual headers to send (or {@code null} if none)
	 */
	
	protected Map!(string, Object) processHeadersToSend(Map!(string, Object) headers) {
		return headers;
	}

}
