/*
 * Copyright 2002-2016 the original author or authors.
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

module hunt.framework.messaging.MessageChannel;

import hunt.framework.messaging.Message;

/**
 * Defines methods for sending messages.
 *
 * @author Mark Fisher
 * @since 4.0
 */
// @FunctionalInterface
interface MessageChannel(T) {

	/**
	 * Constant for sending a message without a prescribed timeout.
	 */
	enum long INDEFINITE_TIMEOUT = -1;


	/**
	 * Send a {@link Message} to this channel. If the message is sent successfully,
	 * the method returns {@code true}. If the message cannot be sent due to a
	 * non-fatal reason, the method returns {@code false}. The method may also
	 * throw a RuntimeException in case of non-recoverable errors.
	 * <p>This method may block indefinitely, depending on the implementation.
	 * To provide a maximum wait time, use {@link #send(Message, long)}.
	 * @param message the message to send
	 * @return whether or not the message was sent
	 */
	final bool send(Message!T message) {
		return send(message, INDEFINITE_TIMEOUT);
	}

	/**
	 * Send a message, blocking until either the message is accepted or the
	 * specified timeout period elapses.
	 * @param message the message to send
	 * @param timeout the timeout in milliseconds or {@link #INDEFINITE_TIMEOUT}
	 * @return {@code true} if the message is sent, {@code false} if not
	 * including a timeout of an interrupt of the send
	 */
	bool send(Message!(T) message, long timeout);

}



/**
 * A {@link MessageChannel} from which messages may be actively received through polling.
 *
 * @author Mark Fisher
 * @since 4.0
 */
interface PollableChannel(T) : MessageChannel!(T) {

	/**
	 * Receive a message from this channel, blocking indefinitely if necessary.
	 * @return the next available {@link Message} or {@code null} if interrupted
	 */
	
	Message!T receive();

	/**
	 * Receive a message from this channel, blocking until either a message is available
	 * or the specified timeout period elapses.
	 * @param timeout the timeout in milliseconds or {@link MessageChannel#INDEFINITE_TIMEOUT}.
	 * @return the next available {@link Message} or {@code null} if the specified timeout
	 * period elapses or the message reception is interrupted
	 */
	
	Message!(T) receive(long timeout);
}



/**
 * A {@link MessageChannel} that maintains a registry of subscribers and invokes
 * them to handle messages sent through this channel.
 *
 * @author Mark Fisher
 * @since 4.0
 */
interface SubscribableChannel(T) : MessageChannel!(T) {

	/**
	 * Register a message handler.
	 * @return {@code true} if the handler was subscribed or {@code false} if it
	 * was already subscribed.
	 */
	bool subscribe(MessageHandler handler);

	/**
	 * Un-register a message handler.
	 * @return {@code true} if the handler was un-registered, or {@code false}
	 * if was not registered.
	 */
	bool unsubscribe(MessageHandler handler);

}
