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

module hunt.framework.messaging.core.AbstractMessagingTemplate;

import hunt.container.Map;

import hunt.framework.messaging.core.AbstractMessageReceivingTemplate;
import hunt.framework.messaging.core.MessageRequestReplyOperations;
import hunt.framework.messaging.Message;

/**
 * An extension of {@link AbstractMessageReceivingTemplate} that adds support for
 * request-reply style operations as defined by {@link MessageRequestReplyOperations}.
 *
 * @author Mark Fisher
 * @author Rossen Stoyanchev
 * @author Stephane Nicoll
 * @since 4.0
 * @param (T) the destination type
 */
abstract class AbstractMessagingTemplate(T) : AbstractMessageReceivingTemplate!(T),
		MessageRequestReplyOperations!(T) {

	// override
	
	// Message!(T) sendAndReceive(Message!(T) requestMessage) {
	// 	return sendAndReceive(getRequiredDefaultDestination(), requestMessage);
	// }

	// override
	
	// Message!(T) sendAndReceive(T destination, Message!(T) requestMessage) {
	// 	return doSendAndReceive(destination, requestMessage);
	// }

	
	// protected abstract Message!(T) doSendAndReceive(T destination, Message!(T) requestMessage);


	// override
	
	// <T> T convertSendAndReceive(Object request, Class!(T) targetClass) {
	// 	return convertSendAndReceive(getRequiredDefaultDestination(), request, targetClass);
	// }

	// override
	
	// <T> T convertSendAndReceive(T destination, Object request, Class!(T) targetClass) {
	// 	return convertSendAndReceive(destination, request, null, targetClass);
	// }

	// override
	
	// <T> T convertSendAndReceive(
	// 		T destination, Object request, Map!(string, Object) headers, Class!(T) targetClass) {

	// 	return convertSendAndReceive(destination, request, headers, targetClass, null);
	// }

	// override
	
	// <T> T convertSendAndReceive(
	// 		Object request, Class!(T) targetClass, MessagePostProcessor postProcessor) {

	// 	return convertSendAndReceive(getRequiredDefaultDestination(), request, targetClass, postProcessor);
	// }

	// override
	
	// <T> T convertSendAndReceive(T destination, Object request, Class!(T) targetClass,
	// 		MessagePostProcessor postProcessor) {

	// 	return convertSendAndReceive(destination, request, null, targetClass, postProcessor);
	// }

	// 
	// override
	
	// <T> T convertSendAndReceive(T destination, Object request, Map!(string, Object) headers,
	// 		Class!(T) targetClass, MessagePostProcessor postProcessor) {

	// 	Message!(T) requestMessage = doConvert(request, headers, postProcessor);
	// 	Message!(T) replyMessage = sendAndReceive(destination, requestMessage);
	// 	return (replyMessage !is null ? (T) getMessageConverter().fromMessage(replyMessage, targetClass) : null);
	// }

}
