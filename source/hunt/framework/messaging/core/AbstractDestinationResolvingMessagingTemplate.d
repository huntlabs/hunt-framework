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

module hunt.framework.messaging.core.AbstractDestinationResolvingMessagingTemplate;

import hunt.framework.messaging.core.AbstractMessagingTemplate;
import hunt.framework.messaging.core.DestinationResolvingMessageSendingOperations;
import hunt.framework.messaging.core.DestinationResolvingMessageReceivingOperations;
import hunt.framework.messaging.core.DestinationResolvingMessageRequestReplyOperations;
import hunt.framework.messaging.Message;

import hunt.container.Map;


/**
 * An extension of {@link AbstractMessagingTemplate} that adds operations for sending
 * messages to a resolvable destination name. Supports destination resolving as defined by
 * the following interfaces:
 * <ul>
 * <li>{@link DestinationResolvingMessageSendingOperations}</li>
 * <li>{@link DestinationResolvingMessageReceivingOperations}</li>
 * <li>{@link DestinationResolvingMessageRequestReplyOperations}</li>
 * </ul>
 *
 * @author Mark Fisher
 * @author Rossen Stoyanchev
 * @since 4.0
 * @param (T) the destination type
 */
abstract class AbstractDestinationResolvingMessagingTemplate(T) : AbstractMessagingTemplate!(T),
		DestinationResolvingMessageSendingOperations!(T),
		DestinationResolvingMessageReceivingOperations!(T),
		DestinationResolvingMessageRequestReplyOperations!(T) {
	
	private DestinationResolver!(T) destinationResolver;


	/**
	 * Configure the {@link DestinationResolver} to use to resolve string destination
	 * names into actual destinations of type {@code !(T)}.
	 * <p>This field does not have a default setting. If not configured, methods that
	 * require resolving a destination name will raise an {@link IllegalArgumentException}.
	 * @param destinationResolver the destination resolver to use
	 */
	void setDestinationResolver(DestinationResolver!(T) destinationResolver) {
		this.destinationResolver = destinationResolver;
	}

	/**
	 * Return the configured destination resolver.
	 */
	
	DestinationResolver!(T) getDestinationResolver() {
		return this.destinationResolver;
	}


	// override
	// void send(string destinationName, MessageBase message) {
	// 	T destination = resolveDestination(destinationName);
	// 	doSend(destination, message);
	// }

	// protected final T resolveDestination(string destinationName) {
	// 	assert(this.destinationResolver !is null, "DestinationResolver is required to resolve destination names");
	// 	return this.destinationResolver.resolveDestination(destinationName);
	// }

	// override
	// <T> void convertAndSend(string destinationName, T payload) {
	// 	convertAndSend(destinationName, payload, null, null);
	// }

	// override
	// <T> void convertAndSend(string destinationName, T payload, Map!(string, Object) headers) {
	// 	convertAndSend(destinationName, payload, headers, null);
	// }

	// override
	// <T> void convertAndSend(string destinationName, T payload, MessagePostProcessor postProcessor) {
	// 	convertAndSend(destinationName, payload, null, postProcessor);
	// }

	// override
	// <T> void convertAndSend(string destinationName, T payload,
	// 		Map!(string, Object) headers, MessagePostProcessor postProcessor) {

	// 	T destination = resolveDestination(destinationName);
	// 	super.convertAndSend(destination, payload, headers, postProcessor);
	// }

	// override
	
	// Message!(T) receive(string destinationName) {
	// 	T destination = resolveDestination(destinationName);
	// 	return super.receive(destination);
	// }

	// override
	
	// <T> T receiveAndConvert(string destinationName, Class!(T) targetClass) {
	// 	T destination = resolveDestination(destinationName);
	// 	return super.receiveAndConvert(destination, targetClass);
	// }

	// override
	
	// Message!(T) sendAndReceive(string destinationName, Message!(T) requestMessage) {
	// 	T destination = resolveDestination(destinationName);
	// 	return super.sendAndReceive(destination, requestMessage);
	// }

	// override
	
	// <T> T convertSendAndReceive(string destinationName, Object request, Class!(T) targetClass) {
	// 	T destination = resolveDestination(destinationName);
	// 	return super.convertSendAndReceive(destination, request, targetClass);
	// }

	// override
	
	// <T> T convertSendAndReceive(string destinationName, Object request,
	// 		Map!(string, Object) headers, Class!(T) targetClass) {

	// 	T destination = resolveDestination(destinationName);
	// 	return super.convertSendAndReceive(destination, request, headers, targetClass);
	// }

	// override
	
	// <T> T convertSendAndReceive(string destinationName, Object request, Class!(T) targetClass,
	// 		MessagePostProcessor postProcessor) {

	// 	T destination = resolveDestination(destinationName);
	// 	return super.convertSendAndReceive(destination, request, targetClass, postProcessor);
	// }

	// override
	
	// <T> T convertSendAndReceive(string destinationName, Object request,
	// 		Map!(string, Object) headers, Class!(T) targetClass,
	// 		MessagePostProcessor postProcessor) {

	// 	T destination = resolveDestination(destinationName);
	// 	return super.convertSendAndReceive(destination, request, headers, targetClass, postProcessor);
	// }

}
