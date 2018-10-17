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

module hunt.framework.messaging.support.AbstractMessageChannel;


// import hunt.framework.messaging.Message;
// import hunt.framework.messaging.MessageChannel;
// import hunt.framework.messaging.MessageDeliveryException;
// import hunt.framework.messaging.MessagingException;

// import hunt.container;
// import hunt.logging;

// // 
// // import hunt.util.ObjectUtils;

// /**
//  * Abstract base class for {@link MessageChannel} implementations.
//  *
//  * @author Rossen Stoyanchev
//  * @since 4.0
//  */
// abstract class AbstractMessageChannel(T) : MessageChannel, InterceptableChannel { // , BeanNameAware

// 	private final List!(ChannelInterceptor) interceptors = new ArrayList<>(5);

// 	private string beanName;


// 	this() {
// 		// this.beanName = getClass().getSimpleName() ~ "@" ~ ObjectUtils.getIdentityHexString(this);
// 	}

// 	private void initialize() {

// 	}



// 	/**
// 	 * A message channel uses the bean name primarily for logging purposes.
// 	 */
// 	override
// 	void setBeanName(string name) {
// 		this.beanName = name;
// 	}

// 	/**
// 	 * Return the bean name for this message channel.
// 	 */
// 	string getBeanName() {
// 		return this.beanName;
// 	}


// 	override
// 	void setInterceptors(List!(ChannelInterceptor) interceptors) {
// 		this.interceptors.clear();
// 		this.interceptors.addAll(interceptors);
// 	}

// 	override
// 	void addInterceptor(ChannelInterceptor interceptor) {
// 		this.interceptors.add(interceptor);
// 	}

// 	override
// 	void addInterceptor(int index, ChannelInterceptor interceptor) {
// 		this.interceptors.add(index, interceptor);
// 	}

// 	override
// 	List!(ChannelInterceptor) getInterceptors() {
// 		return Collections.unmodifiableList(this.interceptors);
// 	}

// 	override
// 	 removeInterceptor(ChannelInterceptor interceptor) {
// 		return this.interceptors.remove(interceptor);
// 	}

// 	override
// 	ChannelInterceptor removeInterceptor(int index) {
// 		return this.interceptors.remove(index);
// 	}


// 	override
// 	final  send(Message!(T) message) {
// 		return send(message, INDEFINITE_TIMEOUT);
// 	}

// 	override
// 	final  send(Message!(T) message, long timeout) {
// 		assert(message, "Message must not be null");
// 		Message!(T) messageToUse = message;
// 		ChannelInterceptorChain chain = new ChannelInterceptorChain();
// 		 sent = false;
// 		try {
// 			messageToUse = chain.applyPreSend(messageToUse, this);
// 			if (messageToUse is null) {
// 				return false;
// 			}
// 			sent = sendInternal(messageToUse, timeout);
// 			chain.applyPostSend(messageToUse, this, sent);
// 			chain.triggerAfterSendCompletion(messageToUse, this, sent, null);
// 			return sent;
// 		}
// 		catch (Exception ex) {
// 			chain.triggerAfterSendCompletion(messageToUse, this, sent, ex);
// 			if (ex instanceof MessagingException) {
// 				throw (MessagingException) ex;
// 			}
// 			throw new MessageDeliveryException(messageToUse,"Failed to send message to " ~ this, ex);
// 		}
// 		catch (Throwable err) {
// 			MessageDeliveryException ex2 =
// 					new MessageDeliveryException(messageToUse, "Failed to send message to " ~ this, err);
// 			chain.triggerAfterSendCompletion(messageToUse, this, sent, ex2);
// 			throw ex2;
// 		}
// 	}

// 	protected abstract  sendInternal(Message!(T) message, long timeout);


// 	override
// 	string toString() {
// 		return getClass().getSimpleName() ~ "[" ~ this.beanName ~ "]";
// 	}


// 	/**
// 	 * Assists with the invocation of the configured channel interceptors.
// 	 */
// 	protected class ChannelInterceptorChain {

// 		private int sendInterceptorIndex = -1;

// 		private int receiveInterceptorIndex = -1;

		
// 		Message!(T) applyPreSend(Message!(T) message, MessageChannel channel) {
// 			Message!(T) messageToUse = message;
// 			for (ChannelInterceptor interceptor : interceptors) {
// 				Message!(T) resolvedMessage = interceptor.preSend(messageToUse, channel);
// 				if (resolvedMessage is null) {
// 					string name = interceptor.getClass().getSimpleName();
// 					version(HUNT_DEBUG) {
// 						trace(name ~ " returned null from preSend, i.e. precluding the send.");
// 					}
// 					triggerAfterSendCompletion(messageToUse, channel, false, null);
// 					return null;
// 				}
// 				messageToUse = resolvedMessage;
// 				this.sendInterceptorIndex++;
// 			}
// 			return messageToUse;
// 		}

// 		void applyPostSend(Message!(T) message, MessageChannel channel,  sent) {
// 			for (ChannelInterceptor interceptor : interceptors) {
// 				interceptor.postSend(message, channel, sent);
// 			}
// 		}

// 		void triggerAfterSendCompletion(Message!(T) message, MessageChannel channel,
// 				 sent, Exception ex) {

// 			for (int i = this.sendInterceptorIndex; i >= 0; i--) {
// 				ChannelInterceptor interceptor = interceptors.get(i);
// 				try {
// 					interceptor.afterSendCompletion(message, channel, sent, ex);
// 				}
// 				catch (Throwable ex2) {
// 					errorf("Exception from afterSendCompletion in " ~ interceptor, ex2);
// 				}
// 			}
// 		}

// 		 applyPreReceive(MessageChannel channel) {
// 			for (ChannelInterceptor interceptor : interceptors) {
// 				if (!interceptor.preReceive(channel)) {
// 					triggerAfterReceiveCompletion(null, channel, null);
// 					return false;
// 				}
// 				this.receiveInterceptorIndex++;
// 			}
// 			return true;
// 		}

		
// 		Message!(T) applyPostReceive(Message!(T) message, MessageChannel channel) {
// 			Message!(T) messageToUse = message;
// 			for (ChannelInterceptor interceptor : interceptors) {
// 				messageToUse = interceptor.postReceive(messageToUse, channel);
// 				if (messageToUse is null) {
// 					return null;
// 				}
// 			}
// 			return messageToUse;
// 		}

// 		void triggerAfterReceiveCompletion(
// 				Message!(T) message, MessageChannel channel, Exception ex) {

// 			for (int i = this.receiveInterceptorIndex; i >= 0; i--) {
// 				ChannelInterceptor interceptor = interceptors.get(i);
// 				try {
// 					interceptor.afterReceiveCompletion(message, channel, ex);
// 				}
// 				catch (Throwable ex2) {
// 					if (logger.isErrorEnabled()) {
// 						errorf("Exception from afterReceiveCompletion in " ~ interceptor, ex2);
// 					}
// 				}
// 			}
// 		}
// 	}

// }
