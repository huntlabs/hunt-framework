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

module hunt.framework.messaging.core.AbstractMessageReceivingTemplate;

import hunt.framework.messaging.core.AbstractMessageSendingTemplate;
import hunt.framework.messaging.core.MessageReceivingOperations;

import hunt.framework.messaging.Message;

import hunt.framework.messaging.converter.MessageConverter;

/**
 * An extension of {@link AbstractMessageSendingTemplate} that adds support for
 * receive style operations as defined by {@link MessageReceivingOperations}.
 *
 * @author Mark Fisher
 * @author Rossen Stoyanchev
 * @author Stephane Nicoll
 * @since 4.1
 * @param (T) the destination type
 */
abstract class AbstractMessageReceivingTemplate(T) : AbstractMessageSendingTemplate!(T),
		MessageReceivingOperations!(T) {

	// override
	
	// public Message!(T) receive() {
	// 	return doReceive(getRequiredDefaultDestination());
	// }

	// override
	
	// public Message!(T) receive(T destination) {
	// 	return doReceive(destination);
	// }

	// /**
	//  * Actually receive a message from the given destination.
	//  * @param destination the target destination
	//  * @return the received message, possibly {@code null} if the message could not
	//  * be received, for example due to a timeout
	//  */
	
	// protected abstract Message!(T) doReceive(T destination);


	// override
	
	// public <T> T receiveAndConvert(Class!(T) targetClass) {
	// 	return receiveAndConvert(getRequiredDefaultDestination(), targetClass);
	// }

	// override
	
	// public <T> T receiveAndConvert(T destination, Class!(T) targetClass) {
	// 	MessageBase message = doReceive(destination);
	// 	if (message !is null) {
	// 		return doConvert(message, targetClass);
	// 	}
	// 	else {
	// 		return null;
	// 	}
	// }

	// /**
	//  * Convert from the given message to the given target class.
	//  * @param message the message to convert
	//  * @param targetClass the target class to convert the payload to
	//  * @return the converted payload of the reply message (never {@code null})
	//  */
	
	
	// protected <T> T doConvert(MessageBase message, Class!(T) targetClass) {
	// 	MessageConverter messageConverter = getMessageConverter();
	// 	T value = (T) messageConverter.fromMessage(message, targetClass);
	// 	if (value is null) {
	// 		throw new MessageConversionException(message, "Unable to convert payload [" ~ message.getPayload() +
	// 				"] to type [" ~ targetClass ~ "] using converter [" ~ messageConverter ~ "]");
	// 	}
	// 	return value;
	// }

}
