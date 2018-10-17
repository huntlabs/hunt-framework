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

import hunt.container.Collection;
import hunt.container.Collections;
import hunt.container.Map;


// import hunt.framework.messaging.Message;
// import hunt.framework.messaging.handler.AbstractMessageCondition;
// import org.springframework.util.Assert;

// /**
//  * {@code MessageCondition} that matches by the message type obtained via
//  * {@link SimpMessageHeaderAccessor#getMessageType(Map)}.
//  *
//  * @author Rossen Stoyanchev
//  * @since 4.0
//  */
// class SimpMessageTypeMessageCondition : AbstractMessageCondition!(SimpMessageTypeMessageCondition) {

// 	static final SimpMessageTypeMessageCondition MESSAGE =
// 			new SimpMessageTypeMessageCondition(SimpMessageType.MESSAGE);

// 	static final SimpMessageTypeMessageCondition SUBSCRIBE =
// 			new SimpMessageTypeMessageCondition(SimpMessageType.SUBSCRIBE);


// 	private final SimpMessageType messageType;


// 	/**
// 	 * A constructor accepting a message type.
// 	 * @param messageType the message type to match messages to
// 	 */
// 	this(SimpMessageType messageType) {
// 		assert(messageType, "MessageType must not be null");
// 		this.messageType = messageType;
// 	}


// 	SimpMessageType getMessageType() {
// 		return this.messageType;
// 	}

// 	override
// 	protected Collection<?> getContent() {
// 		return Collections.singletonList(this.messageType);
// 	}

// 	override
// 	protected string getToStringInfix() {
// 		return " || ";
// 	}

// 	override
// 	SimpMessageTypeMessageCondition combine(SimpMessageTypeMessageCondition other) {
// 		return other;
// 	}

// 	override
	
// 	SimpMessageTypeMessageCondition getMatchingCondition(Message<?> message) {
// 		SimpMessageType actual = SimpMessageHeaderAccessor.getMessageType(message.getHeaders());
// 		return (actual !is null && actual.equals(this.messageType) ? this : null);
// 	}

// 	override
// 	int compareTo(SimpMessageTypeMessageCondition other, Message<?> message) {
// 		Object actual = SimpMessageHeaderAccessor.getMessageType(message.getHeaders());
// 		if (actual !is null) {
// 			if (actual.equals(this.messageType) && actual.equals(other.getMessageType())) {
// 				return 0;
// 			}
// 			else if (actual.equals(this.messageType)) {
// 				return -1;
// 			}
// 			else if (actual.equals(other.getMessageType())) {
// 				return 1;
// 			}
// 		}
// 		return 0;
// 	}

// }
