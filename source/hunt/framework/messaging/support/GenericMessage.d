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

module hunt.framework.messaging.support.GenericMessage;

import hunt.container.Map;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;

import hunt.string;
import hunt.util.ObjectUtils;


/**
 * An implementation of {@link Message} with a generic payload.
 * Once created, a GenericMessage is immutable.
 *
 * @author Mark Fisher
 * @since 4.0
 * @param (T) the payload type
 * @see MessageBuilder
 */
class GenericMessage(T) : Message!(T) {

	private T payload;

	private MessageHeaders headers;


	/**
	 * Create a new message with the given payload.
	 * @param payload the message payload (never {@code null})
	 */
	this(T payload) {
		this(payload, new MessageHeaders(null));
	}

	/**
	 * Create a new message with the given payload and headers.
	 * The content of the given header map is copied.
	 * @param payload the message payload (never {@code null})
	 * @param headers message headers to use for initialization
	 */
	this(T payload, Map!(string, Object) headers) {
		this(payload, new MessageHeaders(headers));
	}

	/**
	 * A constructor with the {@link MessageHeaders} instance to use.
	 * <p><strong>Note:</strong> the given {@code MessageHeaders} instance is used
	 * directly in the new message, i.e. it is not copied.
	 * @param payload the message payload (never {@code null})
	 * @param headers message headers
	 */
	this(T payload, MessageHeaders headers) {
		assert(payload, "Payload must not be null");
		assert(headers, "MessageHeaders must not be null");
		this.payload = payload;
		this.headers = headers;
	}


	T getPayload() {
		return this.payload;
	}

	MessageHeaders getHeaders() {
		return this.headers;
	}


	override bool opEquals(Object other) {
		if (this is other) {
			return true;
		}

		GenericMessage!T otherMsg = cast(GenericMessage!T) other;
		if (otherMsg is null) {
			return false;
		}
		return this.payload == otherMsg.payload && this.headers == otherMsg.headers;
	}

	size_t toHash() @trusted nothrow {
		// Using nullSafeHashCode for proper array toHash handling
		return hashOf(this.payload) * 23 + this.headers.toHash();
	}

	override string toString() {
		StringBuilder sb = new StringBuilder(typeid(this).name);
		sb.append(" [payload=");
		static if(is(T == byte[])) {
			sb.append("byte[").append((cast(byte[]) this.payload).length).append("]");
		} else {
			sb.append(this.payload);
		}
		sb.append(", headers=").append(this.headers).append("]");
		return sb.toString();
	}

}
