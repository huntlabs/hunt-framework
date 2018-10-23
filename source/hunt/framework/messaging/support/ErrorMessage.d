/*
 * Copyright 2002-2017 the original author or authors.
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

module hunt.framework.messaging.support.ErrorMessage;

import hunt.framework.messaging.support.GenericMessage;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;

import hunt.container.Map;


/**
 * A {@link GenericMessage} with a {@link Throwable} payload.
 *
 * <p>The payload is typically a {@link hunt.framework.messaging.MessagingException}
 * with the message at the point of failure in its {@code failedMessage} property.
 * An optional {@code originalMessage} may be provided, which represents the message
 * that existed at the point in the stack where the error message is created.
 *
 * <p>Consider some code that starts with a message, invokes some process that performs
 * transformation on that message and then fails for some reason, throwing the exception.
 * The exception is caught and an error message produced that contains both the original
 * message, and the transformed message that failed.
 *
 * @author Mark Fisher
 * @author Oleg Zhurakousky
 * @author Gary Russell
 * @since 4.0
 * @see MessageBuilder
 */
class ErrorMessage : GenericMessage!(Throwable) {

	// 
	private MessageBase originalMessage;


	/**
	 * Create a new message with the given payload.
	 * @param payload the message payload (never {@code null})
	 */
	this(Throwable payload) {
		super(payload);
		this.originalMessage = null;
	}

	/**
	 * Create a new message with the given payload and headers.
	 * The content of the given header map is copied.
	 * @param payload the message payload (never {@code null})
	 * @param headers message headers to use for initialization
	 */
	this(Throwable payload, Map!(string, Object) headers) {
		super(payload, headers);
		this.originalMessage = null;
	}

	/**
	 * A constructor with the {@link MessageHeaders} instance to use.
	 * <p><strong>Note:</strong> the given {@code MessageHeaders} instance
	 * is used directly in the new message, i.e. it is not copied.
	 * @param payload the message payload (never {@code null})
	 * @param headers message headers
	 */
	this(Throwable payload, MessageHeaders headers) {
		super(payload, headers);
		this.originalMessage = null;
	}

	/**
	 * Create a new message with the given payload and original message.
	 * @param payload the message payload (never {@code null})
	 * @param originalMessage the original message (if present) at the point
	 * in the stack where the ErrorMessage was created
	 * @since 5.0
	 */
	this(Throwable payload, MessageBase originalMessage) {
		super(payload);
		this.originalMessage = originalMessage;
	}

	/**
	 * Create a new message with the given payload, headers and original message.
	 * The content of the given header map is copied.
	 * @param payload the message payload (never {@code null})
	 * @param headers message headers to use for initialization
	 * @param originalMessage the original message (if present) at the point
	 * in the stack where the ErrorMessage was created
	 * @since 5.0
	 */
	this(Throwable payload, Map!(string, Object) headers, MessageBase originalMessage) {
		super(payload, headers);
		this.originalMessage = originalMessage;
	}

	/**
	 * Create a new message with the payload, {@link MessageHeaders} and original message.
	 * <p><strong>Note:</strong> the given {@code MessageHeaders} instance
	 * is used directly in the new message, i.e. it is not copied.
	 * @param payload the message payload (never {@code null})
	 * @param headers message headers
	 * @param originalMessage the original message (if present) at the point
	 * in the stack where the ErrorMessage was created
	 * @since 5.0
	 */
	this(Throwable payload, MessageHeaders headers, MessageBase originalMessage) {
		super(payload, headers);
		this.originalMessage = originalMessage;
	}


	/**
	 * Return the original message (if available) at the point in the stack
	 * where the ErrorMessage was created.
	 * @since 5.0
	 */
	
	MessageBase getOriginalMessage() {
		return this.originalMessage;
	}

	override
	string toString() {
		if (this.originalMessage is null) {
			return super.toString();
		}
		return super.toString() ~ " for original " ~ (cast(Object)this.originalMessage).toString();
	}

}
