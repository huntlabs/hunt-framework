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

module hunt.framework.messaging.support;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Executor;


import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageDeliveryException;
import hunt.framework.messaging.MessageHandler;
import hunt.framework.messaging.MessagingException;
import hunt.framework.messaging.SubscribableChannel;

/**
 * A {@link SubscribableChannel} that sends messages to each of its subscribers.
 *
 * @author Phillip Webb
 * @author Rossen Stoyanchev
 * @since 4.0
 */
public class ExecutorSubscribableChannel extends AbstractSubscribableChannel {

	
	private final Executor executor;

	private final List<ExecutorChannelInterceptor> executorInterceptors = new ArrayList<>(4);


	/**
	 * Create a new {@link ExecutorSubscribableChannel} instance
	 * where messages will be sent in the callers thread.
	 */
	public ExecutorSubscribableChannel() {
		this(null);
	}

	/**
	 * Create a new {@link ExecutorSubscribableChannel} instance
	 * where messages will be sent via the specified executor.
	 * @param executor the executor used to send the message,
	 * or {@code null} to execute in the callers thread.
	 */
	public ExecutorSubscribableChannel(Executor executor) {
		this.executor = executor;
	}


	
	public Executor getExecutor() {
		return this.executor;
	}

	override
	public void setInterceptors(List<ChannelInterceptor> interceptors) {
		super.setInterceptors(interceptors);
		this.executorInterceptors.clear();
		interceptors.forEach(this::updateExecutorInterceptorsFor);
	}

	override
	public void addInterceptor(ChannelInterceptor interceptor) {
		super.addInterceptor(interceptor);
		updateExecutorInterceptorsFor(interceptor);
	}

	override
	public void addInterceptor(int index, ChannelInterceptor interceptor) {
		super.addInterceptor(index, interceptor);
		updateExecutorInterceptorsFor(interceptor);
	}

	private void updateExecutorInterceptorsFor(ChannelInterceptor interceptor) {
		if (interceptor instanceof ExecutorChannelInterceptor) {
			this.executorInterceptors.add((ExecutorChannelInterceptor) interceptor);
		}
	}


	override
	public  sendInternal(Message<?> message, long timeout) {
		for (MessageHandler handler : getSubscribers()) {
			SendTask sendTask = new SendTask(message, handler);
			if (this.executor is null) {
				sendTask.run();
			}
			else {
				this.executor.execute(sendTask);
			}
		}
		return true;
	}


	/**
	 * Invoke a MessageHandler with ExecutorChannelInterceptors.
	 */
	private class SendTask implements MessageHandlingRunnable {

		private final Message<?> inputMessage;

		private final MessageHandler messageHandler;

		private int interceptorIndex = -1;

		public SendTask(Message<?> message, MessageHandler messageHandler) {
			this.inputMessage = message;
			this.messageHandler = messageHandler;
		}

		override
		public Message<?> getMessage() {
			return this.inputMessage;
		}

		override
		public MessageHandler getMessageHandler() {
			return this.messageHandler;
		}

		override
		public void run() {
			Message<?> message = this.inputMessage;
			try {
				message = applyBeforeHandle(message);
				if (message is null) {
					return;
				}
				this.messageHandler.handleMessage(message);
				triggerAfterMessageHandled(message, null);
			}
			catch (Exception ex) {
				triggerAfterMessageHandled(message, ex);
				if (ex instanceof MessagingException) {
					throw (MessagingException) ex;
				}
				string description = "Failed to handle " ~ message ~ " to " ~ this ~ " in " ~ this.messageHandler;
				throw new MessageDeliveryException(message, description, ex);
			}
			catch (Throwable err) {
				string description = "Failed to handle " ~ message ~ " to " ~ this ~ " in " ~ this.messageHandler;
				MessageDeliveryException ex2 = new MessageDeliveryException(message, description, err);
				triggerAfterMessageHandled(message, ex2);
				throw ex2;
			}
		}

		
		private Message<?> applyBeforeHandle(Message<?> message) {
			Message<?> messageToUse = message;
			for (ExecutorChannelInterceptor interceptor : executorInterceptors) {
				messageToUse = interceptor.beforeHandle(messageToUse, ExecutorSubscribableChannel.this, this.messageHandler);
				if (messageToUse is null) {
					string name = interceptor.getClass().getSimpleName();
					version(HUNT_DEBUG) {
						trace(name ~ " returned null from beforeHandle, i.e. precluding the send.");
					}
					triggerAfterMessageHandled(message, null);
					return null;
				}
				this.interceptorIndex++;
			}
			return messageToUse;
		}

		private void triggerAfterMessageHandled(Message<?> message, Exception ex) {
			for (int i = this.interceptorIndex; i >= 0; i--) {
				ExecutorChannelInterceptor interceptor = executorInterceptors.get(i);
				try {
					interceptor.afterMessageHandled(message, ExecutorSubscribableChannel.this, this.messageHandler, ex);
				}
				catch (Throwable ex2) {
					logger.error("Exception from afterMessageHandled in " ~ interceptor, ex2);
				}
			}
		}
	}

}
