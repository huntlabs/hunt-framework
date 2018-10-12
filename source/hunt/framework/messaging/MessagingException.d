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

module hunt.framework.messaging;

import hunt.framework.messaging.exception;
import hunt.framework.messaging.Message;

import hunt.util.exception;


class NestedRuntimeException : Exception
{
    mixin BasicExceptionCtors;
}



/**
 * The base exception for any failures related to messaging.
 *
 * @author Mark Fisher
 * @author Gary Russell
 * @since 4.0
 */

class MessagingException(T) : NestedRuntimeException {
	
	private Message!(T) failedMessage;


	this(Message!(T) message) {
		super(null, null);
		this.failedMessage = message;
	}

	this(string description) {
		super(description);
		this.failedMessage = null;
	}

	this(string description, Throwable cause) {
		super(description, cause);
		this.failedMessage = null;
	}

	this(Message!(T) message, string description) {
		super(description);
		this.failedMessage = message;
	}

	this(Message!(T) message, Throwable cause) {
		super(null, cause);
		this.failedMessage = message;
	}

	this(Message!(T) message, string description, Throwable cause) {
		super(description, cause);
		this.failedMessage = message;
	}
	
	Message!(T) getFailedMessage() {
		return this.failedMessage;
	}

	override
	string toString() {
		return super.toString() ~ (this.failedMessage is null ? ""
				: (", failedMessage=" ~ this.failedMessage));
	}

}



/**
 * Exception that indicates an error occurred during message handling.
 *
 * @author Mark Fisher
 * @since 4.0
 */

class MessageHandlingException : MessagingException {

	this(Message!(T) failedMessage) {
		super(failedMessage);
	}

	this(Message!(T) message, string description) {
		super(message, description);
	}

	this(Message!(T) failedMessage, Throwable cause) {
		super(failedMessage, cause);
	}

	this(Message!(T) message, string description, Throwable cause) {
		super(message, description, cause);
	}

}


/**
 * Exception that indicates an error occurred during message delivery.
 *
 * @author Mark Fisher
 * @since 4.0
 */

class MessageDeliveryException(T) : MessagingException!T {

	this(string description) {
		super(description);
	}

	this(Message!(T) undeliveredMessage) {
		super(undeliveredMessage);
	}

	this(Message!(T) undeliveredMessage, string description) {
		super(undeliveredMessage, description);
	}

	this(Message!(T) message, Throwable cause) {
		super(message, cause);
	}

	this(Message!(T) undeliveredMessage, string description, Throwable cause) {
		super(undeliveredMessage, description, cause);
	}

}
