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

module hunt.framework.messaging.simp.SimpMessageTypeMessageCondition;

import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
import hunt.framework.messaging.simp.SimpMessageType;
import hunt.container;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.handler.AbstractMessageCondition;

/**
 * {@code MessageCondition} that matches by the message type obtained via
 * {@link SimpMessageHeaderAccessor#getMessageType(Map)}.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class SimpMessageTypeMessageCondition : 
    AbstractMessageCondition!(SimpMessageTypeMessageCondition, SimpMessageType) {

	__gshared SimpMessageTypeMessageCondition MESSAGE;
	__gshared SimpMessageTypeMessageCondition SUBSCRIBE;

	private SimpMessageType messageType;

    shared static this() {
        MESSAGE = new SimpMessageTypeMessageCondition(SimpMessageType.MESSAGE);
        SUBSCRIBE = new SimpMessageTypeMessageCondition(SimpMessageType.SUBSCRIBE);
    }


	/**
	 * A constructor accepting a message type.
	 * @param messageType the message type to match messages to
	 */
	this(SimpMessageType messageType) {
		assert(messageType, "MessageType must not be null");
		this.messageType = messageType;
	}


	SimpMessageType getMessageType() {
		return this.messageType;
	}

// TODO: Tasks pending completion -@zxp at 10/31/2018, 10:40:58 AM
// 
	override
	protected Collection!SimpMessageType getContent() {
		return Collections.singletonList(this.messageType);
	}

	override
	protected string getToStringInfix() {
		return " || ";
	}

	// override
	SimpMessageTypeMessageCondition combine(SimpMessageTypeMessageCondition other) {
		return other;
	}

	// override
	SimpMessageTypeMessageCondition getMatchingCondition(MessageBase message) {
		Nullable!SimpMessageType actual = SimpMessageHeaderAccessor.getMessageType(message.getHeaders());
		return (actual !is null && actual == this.messageType ? this : null);
	}

	// override
	int compareTo(SimpMessageTypeMessageCondition other, MessageBase message) {
		Nullable!SimpMessageType actual = SimpMessageHeaderAccessor.getMessageType(message.getHeaders());
		if (actual !is null) {
            SimpMessageType actualType = cast(SimpMessageType)actual;
			if (actualType == this.messageType && actualType == other.getMessageType()) {
				return 0;
			}
			else if (actualType == this.messageType) {
				return -1;
			}
			else if (actualType == other.getMessageType()) {
				return 1;
			}
		}
		return 0;
	}

}
