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

module hunt.framework.messaging.support.ChannelInterceptorAdapter;


// import hunt.framework.messaging.Message;
// import hunt.framework.messaging.MessageChannel;

// /**
//  * A {@link ChannelInterceptor} base class with empty method implementations
//  * as a convenience.
//  *
//  * @author Mark Fisher
//  * @author Rossen Stoyanchev
//  * @since 4.0
//  * @deprecated as of 5.0.7 {@link ChannelInterceptor} has default methods (made
//  * possible by a Java 8 baseline) and can be implemented directly without the
//  * need for this no-op adapter
//  */
// @Deprecated
// abstract class ChannelInterceptorAdapter : ChannelInterceptor {

// 	override
// 	Message<?> preSend(Message<?> message, MessageChannel channel) {
// 		return message;
// 	}

// 	override
// 	void postSend(Message<?> message, MessageChannel channel,  sent) {
// 	}

// 	override
// 	void afterSendCompletion(Message<?> message, MessageChannel channel,  sent, Exception ex) {
// 	}

// 	 preReceive(MessageChannel channel) {
// 		return true;
// 	}

// 	override
// 	Message<?> postReceive(Message<?> message, MessageChannel channel) {
// 		return message;
// 	}

// 	override
// 	void afterReceiveCompletion(Message<?> message, MessageChannel channel, Exception ex) {
// 	}

// }
