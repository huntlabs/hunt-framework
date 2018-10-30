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

import hunt.framework.messaging.support.ChannelInterceptor;
import hunt.framework.messaging.support.InterceptableChannel;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageChannel;
import hunt.framework.messaging.MessagingException;

import hunt.lang.object;
import hunt.container;
import hunt.logging;
import hunt.util.ObjectUtils;
import hunt.util.TypeUtils;

/**
 * Abstract base class for {@link MessageChannel} implementations.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
abstract class AbstractMessageChannel : MessageChannel, InterceptableChannel { // , BeanNameAware

	private List!(ChannelInterceptor) interceptors;

	private string beanName;


	this() {
		this.beanName = TypeUtils.getSimpleName(typeid(this)) ~ "@" ~ ObjectUtils.getIdentityHexString(this);
	}

	private void initialize() {
		interceptors = new ArrayList!ChannelInterceptor(5);
	}



	/**
	 * A message channel uses the bean name primarily for logging purposes.
	 */
	// override
	void setBeanName(string name) {
		this.beanName = name;
	}

	/**
	 * Return the bean name for this message channel.
	 */
	string getBeanName() {
		return this.beanName;
	}


	override
	void setInterceptors(List!(ChannelInterceptor) interceptors) {
		this.interceptors.clear();
		this.interceptors.addAll(interceptors);
	}

	override
	void addInterceptor(ChannelInterceptor interceptor) {
		this.interceptors.add(interceptor);
	}

	override
	void addInterceptor(int index, ChannelInterceptor interceptor) {
		this.interceptors.add(index, interceptor);
	}

	override
	List!(ChannelInterceptor) getInterceptors() {
		return Collections.unmodifiableList(this.interceptors);
	}

	override
	bool removeInterceptor(ChannelInterceptor interceptor) {
		return this.interceptors.remove(interceptor);
	}

	override
	ChannelInterceptor removeInterceptor(int index) {
		return this.interceptors.remove(index);
	}

	// override
	// bool send(MessageBase message) {
	// 	return send(message, INDEFINITE_TIMEOUT);
	// }

	override
	bool send(MessageBase message, long timeout) {
		assert(message !is null, "Message must not be null");
		MessageBase messageToUse = message;
		ChannelInterceptorChain chain = new ChannelInterceptorChain();
		 sent = false;
		try {
			messageToUse = chain.applyPreSend(messageToUse, this);
			if (messageToUse is null) {
				return false;
			}
			sent = sendInternal(messageToUse, timeout);
			chain.applyPostSend(messageToUse, this, sent);
			chain.triggerAfterSendCompletion(messageToUse, this, sent, null);
			return sent;
		}
		catch (Exception ex) {
			chain.triggerAfterSendCompletion(messageToUse, this, sent, ex);
			MessagingException mex = cast(MessagingException) ex;
			if (mex !is null) 
				throw mex;
			throw new MessageDeliveryException(messageToUse,"Failed to send message to " ~ this.toString(), ex);
		}
		catch (Throwable err) {
			MessageDeliveryException ex2 =
					new MessageDeliveryException(messageToUse, "Failed to send message to " ~ this.toString(), err);
			chain.triggerAfterSendCompletion(messageToUse, this, sent, ex2);
			throw ex2;
		}
	}

	protected abstract bool sendInternal(MessageBase message, long timeout);


	override
	string toString() {
		return TypeUtils.getSimpleName(typeid(this)) ~ "[" ~ this.beanName ~ "]";
	}


	/**
	 * Assists with the invocation of the configured channel interceptors.
	 */
	protected class ChannelInterceptorChain {

		private int sendInterceptorIndex = -1;

		private int receiveInterceptorIndex = -1;

		
		MessageBase applyPreSend(MessageBase message, MessageChannel channel) {
			MessageBase messageToUse = message;
			foreach (ChannelInterceptor interceptor ; interceptors) {
				MessageBase resolvedMessage = interceptor.preSend(messageToUse, channel);
				if (resolvedMessage is null) {
					string name = TypeUtils.getSimpleName(typeid(interceptor));
					version(HUNT_DEBUG) {
						trace(name ~ " returned null from preSend, i.e. precluding the send.");
					}
					triggerAfterSendCompletion(messageToUse, channel, false, null);
					return null;
				}
				messageToUse = resolvedMessage;
				this.sendInterceptorIndex++;
			}
			return messageToUse;
		}

		void applyPostSend(MessageBase message, MessageChannel channel, bool sent) {
			foreach (ChannelInterceptor interceptor ; interceptors) {
				interceptor.postSend(message, channel, sent);
			}
		}

		void triggerAfterSendCompletion(MessageBase message, MessageChannel channel,
				bool sent, Exception ex) {
			for (int i = this.sendInterceptorIndex; i >= 0; i--) {
				ChannelInterceptor interceptor = interceptors.get(i);
				try {
					interceptor.afterSendCompletion(message, channel, sent, ex);
				}
				catch (Throwable ex2) {
					errorf("Exception from afterSendCompletion in " ~ interceptor, ex2);
				}
			}
		}

		bool applyPreReceive(MessageChannel channel) {
			foreach (ChannelInterceptor interceptor ; interceptors) {
				if (!interceptor.preReceive(channel)) {
					triggerAfterReceiveCompletion(null, channel, null);
					return false;
				}
				this.receiveInterceptorIndex++;
			}
			return true;
		}

		
		MessageBase applyPostReceive(MessageBase message, MessageChannel channel) {
			MessageBase messageToUse = message;
			foreach (ChannelInterceptor interceptor ; interceptors) {
				messageToUse = interceptor.postReceive(messageToUse, channel);
				if (messageToUse is null) {
					return null;
				}
			}
			return messageToUse;
		}

		void triggerAfterReceiveCompletion(MessageBase message, 
			MessageChannel channel, Exception ex) {

			for (int i = this.receiveInterceptorIndex; i >= 0; i--) {
				ChannelInterceptor interceptor = interceptors.get(i);
				try {
					interceptor.afterReceiveCompletion(message, channel, ex);
				}
				catch (Throwable ex2) {
					version(HUNT_DEBUG) {
						errorf("Exception from afterReceiveCompletion in " ~ interceptor, ex2);
					}
				}
			}
		}
	}

}
