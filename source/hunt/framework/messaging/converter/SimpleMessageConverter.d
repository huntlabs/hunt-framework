/*
 * Copyright 2002-2014 the original author or authors.
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

module hunt.framework.messaging.converter.SimpleMessageConverter;

import hunt.framework.messaging.converter.MessageConverter;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;

/**
 * A simple converter that simply unwraps the message payload as long as it matches the
 * expected target class. Or reversely, simply wraps the payload in a message.
 *
 * <p>Note that this converter ignores any content type information that may be present in
 * message headers and should not be used if payload conversion is actually required.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
public class SimpleMessageConverter(T) : MessageConverter!(T) {

	// override
	
	// public Object fromMessage(Message!(T) message, Class!(T) targetClass) {
	// 	Object payload = message.getPayload();
	// 	return (ClassUtils.isAssignableValue(targetClass, payload) ? payload : null);
	// }

	// override
	// public Message!(T) toMessage(Object payload, MessageHeaders headers) {
	// 	if (headers !is null) {
	// 		MessageHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(headers, MessageHeaderAccessor.class);
	// 		if (accessor !is null && accessor.isMutable()) {
	// 			return MessageBuilder.createMessage(payload, accessor.getMessageHeaders());
	// 		}
	// 	}
	// 	return MessageBuilder.withPayload(payload).copyHeaders(headers).build();
	// }

}
