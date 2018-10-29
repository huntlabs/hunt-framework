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

module hunt.framework.messaging.MessagingException;

import hunt.framework.messaging.exception;
import hunt.framework.messaging.Message;

// import hunt.lang.exception;


/**
 * The base exception for any failures related to messaging.
 *
 * @author Mark Fisher
 * @author Gary Russell
 * @since 4.0
 */

class MessagingException : NestedRuntimeException {
	
	private MessageBase failedMessage;


	this(MessageBase message) {
		super("");
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

	this(MessageBase message, string description) {
		super(description);
		this.failedMessage = message;
	}

	this(MessageBase message, Throwable cause) {
		super(null, cause);
		this.failedMessage = message;
	}

	this(MessageBase message, string description, Throwable cause) {
		super(description, cause);
		this.failedMessage = message;
	}
	
	MessageBase getFailedMessage() {
		return this.failedMessage;
	}

	override
	string toString() {
		return super.toString() ~ (this.failedMessage is null ? ""
				: (", failedMessage=" ~ (cast(Object)this.failedMessage).toString()));
	}

}



/**
 * Exception that indicates an error occurred during message handling.
 *
 * @author Mark Fisher
 * @since 4.0
 */

class MessageHandlingException : MessagingException {

	this(MessageBase failedMessage) {
		super(failedMessage);
	}

	this(MessageBase message, string description) {
		super(message, description);
	}

	this(MessageBase failedMessage, Throwable cause) {
		super(failedMessage, cause);
	}

	this(MessageBase message, string description, Throwable cause) {
		super(message, description, cause);
	}

}


/**
 * Exception that indicates an error occurred during message delivery.
 *
 * @author Mark Fisher
 * @since 4.0
 */

class MessageDeliveryException : MessagingException {

	this(string description) {
		super(description);
	}

	this(MessageBase undeliveredMessage) {
		super(undeliveredMessage);
	}

	this(MessageBase undeliveredMessage, string description) {
		super(undeliveredMessage, description);
	}

	this(MessageBase message, Throwable cause) {
		super(message, cause);
	}

	this(MessageBase undeliveredMessage, string description, Throwable cause) {
		super(undeliveredMessage, description, cause);
	}

}


/**
 * {@link MessagingException} thrown when a session is missing.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */

class MissingSessionUserException : MessagingException {

	this(MessageBase message) {
		super(message, "No \"user\" header in message");
	}

}