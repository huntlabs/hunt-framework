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

module hunt.framework.messaging.core.MessageSendingOperations;

import hunt.framework.messaging.core.MessagePostProcessor;
import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessagingException;

import hunt.container.Map;

/**
 * Operations for sending messages to a destination.
 *
 * @author Mark Fisher
 * @author Rossen Stoyanchev
 * @since 4.0
 * @param (T) the destination type
 */
interface MessageSendingOperations(T) {

	/**
	 * Send a message to a default destination.
	 * @param message the message to send
	 */
	void send(MessageBase message);

	/**
	 * Send a message to the given destination.
	 * @param destination the target destination
	 * @param message the message to send
	 */
	void send(T destination, MessageBase message);

	/**
	 * Convert the given Object to serialized form, possibly using a
	 * {@link hunt.framework.messaging.converter.MessageConverter},
	 * wrap it as a message and send it to a default destination.
	 * @param payload the Object to use as payload
	 */
	void convertAndSend(Object payload);

	/**
	 * Convert the given Object to serialized form, possibly using a
	 * {@link hunt.framework.messaging.converter.MessageConverter},
	 * wrap it as a message and send it to the given destination.
	 * @param destination the target destination
	 * @param payload the Object to use as payload
	 */
	void convertAndSend(T destination, Object payload);

	/**
	 * Convert the given Object to serialized form, possibly using a
	 * {@link hunt.framework.messaging.converter.MessageConverter},
	 * wrap it as a message with the given headers and send it to
	 * the given destination.
	 * @param destination the target destination
	 * @param payload the Object to use as payload
	 * @param headers headers for the message to send
	 */
	void convertAndSend(T destination, Object payload, Map!(string, Object) headers);

	/**
	 * Convert the given Object to serialized form, possibly using a
	 * {@link hunt.framework.messaging.converter.MessageConverter},
	 * wrap it as a message, apply the given post processor, and send
	 * the resulting message to a default destination.
	 * @param payload the Object to use as payload
	 * @param postProcessor the post processor to apply to the message
	 */
	void convertAndSend(Object payload, MessagePostProcessor!T postProcessor);

	/**
	 * Convert the given Object to serialized form, possibly using a
	 * {@link hunt.framework.messaging.converter.MessageConverter},
	 * wrap it as a message, apply the given post processor, and send
	 * the resulting message to the given destination.
	 * @param destination the target destination
	 * @param payload the Object to use as payload
	 * @param postProcessor the post processor to apply to the message
	 */
	void convertAndSend(T destination, Object payload, MessagePostProcessor!T postProcessor);

	/**
	 * Convert the given Object to serialized form, possibly using a
	 * {@link hunt.framework.messaging.converter.MessageConverter},
	 * wrap it as a message with the given headers, apply the given post processor,
	 * and send the resulting message to the given destination.
	 * @param destination the target destination
	 * @param payload the Object to use as payload
	 * @param headers headers for the message to send
	 * @param postProcessor the post processor to apply to the message
	 */
	void convertAndSend(T destination, Object payload, Map!(string, Object) headers,
			MessagePostProcessor!T postProcessor);

}
