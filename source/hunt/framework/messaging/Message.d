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

module hunt.framework.messaging.Message;

import hunt.framework.messaging.MessageHeaders;
import hunt.lang.common;

/**
* See_also:
*	https://docs.spring.io/spring/docs/current/spring-framework-reference/web.html#websocket-stomp-message-flow
*/
interface MessageBase {

	TypeInfo  payloadType();

	/**
	 * Return message headers for the message (never {@code null} but may be empty).
	 */
	MessageHeaders getHeaders();

}

/**
 * A generic message representation with headers and body.
 *
 * @author Mark Fisher
 * @author Arjen Poutsma
 * @since 4.0
 * @param (T) the payload type
 * @see hunt.framework.messaging.support.MessageBuilder
 */
interface Message(T) : MessageBase {

	/**
	 * Return the message payload.
	 */
	T getPayload();

	/**
	 * Return message headers for the message (never {@code null} but may be empty).
	 */
	// MessageHeaders getHeaders();
}

/**
 * Contract for handling a {@link Message}.
 *
 * @author Mark Fisher
 * @author Iwein Fuld
 * @since 4.0
 */
interface MessageHandler {

	/**
	 * Handle the given message.
	 * @param message the message to be handled
	 * @throws MessagingException if the handler failed to process the message
	 */
	void handleMessage(MessageBase message);

	int opCmp(MessageHandler o);
}


/**
 * Extension of the {@link Runnable} interface with methods to obtain the
 * {@link MessageHandler} and {@link Message} to be handled.
 *
 * @author Rossen Stoyanchev
 * @since 4.1.1
 */
interface MessageHandlingRunnable : Runnable {

	/**
	 * Return the Message that will be handled.
	 */
	MessageBase getMessage();

	/**
	 * Return the MessageHandler that will be used to handle the message.
	 */
	MessageHandler getMessageHandler();

}