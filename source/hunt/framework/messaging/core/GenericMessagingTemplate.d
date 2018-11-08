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

module hunt.framework.messaging.core.GenericMessagingTemplate;


import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageChannel;
import hunt.framework.messaging.MessagingException;
import hunt.framework.messaging.MessageHeaders;
import hunt.framework.messaging.support.MessageBuilder;
import hunt.framework.messaging.support.MessageHeaderAccessor;

// import java.util.concurrent.CountDownLatch;

import hunt.lang.Nullable;
import hunt.lang.Number;
import hunt.logging;

// import hunt.framework.beans.BeansException;
// import hunt.framework.beans.factory.BeanFactory;
// import hunt.framework.beans.factory.BeanFactoryAware;

import std.conv;


/**
 * A messaging template that resolves destinations names to {@link MessageChannel}'s
 * to send and receive messages from.
 *
 * @author Mark Fisher
 * @author Rossen Stoyanchev
 * @author Gary Russell
 * @since 4.0
 */
class GenericMessagingTemplate(T) : AbstractDestinationResolvingMessagingTemplate!MessageChannel
		{ // implements BeanFactoryAware

	/**
	 * The default header key used for a send timeout.
	 */
	enum string DEFAULT_SEND_TIMEOUT_HEADER = "sendTimeout";

	/**
	 * The default header key used for a receive timeout.
	 */
	enum string DEFAULT_RECEIVE_TIMEOUT_HEADER = "receiveTimeout";

	private long sendTimeout = -1;

	private long receiveTimeout = -1;

	private string sendTimeoutHeader = DEFAULT_SEND_TIMEOUT_HEADER;

	private string receiveTimeoutHeader = DEFAULT_RECEIVE_TIMEOUT_HEADER;

	private bool throwExceptionOnLateReply = false;


	/**
	 * Configure the default timeout value to use for send operations.
	 * May be overridden for individual messages.
	 * @param sendTimeout the send timeout in milliseconds
	 * @see #setSendTimeoutHeader(string)
	 */
	void setSendTimeout(long sendTimeout) {
		this.sendTimeout = sendTimeout;
	}

	/**
	 * Return the configured default send operation timeout value.
	 */
	long getSendTimeout() {
		return this.sendTimeout;
	}

	/**
	 * Configure the default timeout value to use for receive operations.
	 * May be overridden for individual messages when using sendAndReceive
	 * operations.
	 * @param receiveTimeout the receive timeout in milliseconds
	 * @see #setReceiveTimeoutHeader(string)
	 */
	void setReceiveTimeout(long receiveTimeout) {
		this.receiveTimeout = receiveTimeout;
	}

	/**
	 * Return the configured receive operation timeout value.
	 */
	long getReceiveTimeout() {
		return this.receiveTimeout;
	}

	/**
	 * Set the name of the header used to determine the send timeout (if present).
	 * Default {@value #DEFAULT_SEND_TIMEOUT_HEADER}.
	 * <p>The header is removed before sending the message to avoid propagation.
	 * @since 5.0
	 */
	void setSendTimeoutHeader(string sendTimeoutHeader) {
		assert(sendTimeoutHeader, "'sendTimeoutHeader' cannot be null");
		this.sendTimeoutHeader = sendTimeoutHeader;
	}

	/**
	 * Return the configured send-timeout header.
	 * @since 5.0
	 */
	string getSendTimeoutHeader() {
		return this.sendTimeoutHeader;
	}

	/**
	 * Set the name of the header used to determine the send timeout (if present).
	 * Default {@value #DEFAULT_RECEIVE_TIMEOUT_HEADER}.
	 * The header is removed before sending the message to avoid propagation.
	 * @since 5.0
	 */
	void setReceiveTimeoutHeader(string receiveTimeoutHeader) {
		assert(receiveTimeoutHeader, "'receiveTimeoutHeader' cannot be null");
		this.receiveTimeoutHeader = receiveTimeoutHeader;
	}

	/**
	 * Return the configured receive-timeout header.
	 * @since 5.0
	 */
	string getReceiveTimeoutHeader() {
		return this.receiveTimeoutHeader;
	}

	/**
	 * Whether the thread sending a reply should have an exception raised if the
	 * receiving thread isn't going to receive the reply either because it timed out,
	 * or because it already received a reply, or because it got an exception while
	 * sending the request message.
	 * <p>The default value is {@code false} in which case only a WARN message is logged.
	 * If set to {@code true} a {@link MessageDeliveryException} is raised in addition
	 * to the log message.
	 * @param throwExceptionOnLateReply whether to throw an exception or not
	 */
	void setThrowExceptionOnLateReply(bool throwExceptionOnLateReply) {
		this.throwExceptionOnLateReply = throwExceptionOnLateReply;
	}

	override
	void setBeanFactory(BeanFactory beanFactory) {
		setDestinationResolver(new BeanFactoryMessageChannelDestinationResolver(beanFactory));
	}


	override
	protected final void doSend(MessageChannel channel, MessageBase message) {
		doSend(channel, message, sendTimeout(message));
	}

	protected final void doSend(MessageChannel channel, MessageBase message, long timeout) {
		assert(channel, "MessageChannel is required");

		// Message!(T) messageToSend = message;
		// MessageHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, MessageHeaderAccessor.class);
		// if (accessor !is null && accessor.isMutable()) {
		// 	accessor.removeHeader(this.sendTimeoutHeader);
		// 	accessor.removeHeader(this.receiveTimeoutHeader);
		// 	accessor.setImmutable();
		// }
		// else if (message.getHeaders().containsKey(this.sendTimeoutHeader)
		// 		|| message.getHeaders().containsKey(this.receiveTimeoutHeader)) {
		// 	messageToSend = MessageBuilder.fromMessage(message)
		// 			.setHeader(this.sendTimeoutHeader, null)
		// 			.setHeader(this.receiveTimeoutHeader, null)
		// 			.build();
		// }

		// bool sent = (timeout >= 0 ? channel.send(messageToSend, timeout) : channel.send(messageToSend));

		// if (!sent) {
		// 	throw new MessageDeliveryException(message,
		// 			"Failed to send message to channel '" ~ channel ~ "' within timeout: " ~ timeout);
		// }
	}

	override
	
	protected final Message!(T) doReceive(MessageChannel channel) {
		return doReceive(channel, this.receiveTimeout);
	}

	
	protected final Message!(T) doReceive(MessageChannel channel, long timeout) {
		assert(channel, "MessageChannel is required");
		PollableChannel pollChannel = cast(PollableChannel) channel;
		assert(pollChannel !is null, "A PollableChannel is required to receive messages");

		MessageBase message = (timeout >= 0 ?
				pollChannel.receive(timeout) : pollChannel.receive());

		if (message is null && logger.isTraceEnabled()) {
			trace("Failed to receive message from channel '" ~ channel ~ "' within timeout: " ~ timeout.to!string());
		}

		return message;
	}

	override
	
	protected final Message!(T) doSendAndReceive(MessageChannel channel, Message!(T) requestMessage) {
		assert(channel, "'channel' is required");
		Object originalReplyChannelHeader = requestMessage.getHeaders().getReplyChannel();
		Object originalErrorChannelHeader = requestMessage.getHeaders().getErrorChannel();

		long sendTimeout = sendTimeout(requestMessage);
		long receiveTimeout = receiveTimeout(requestMessage);

		TemporaryReplyChannel tempReplyChannel = new TemporaryReplyChannel(this.throwExceptionOnLateReply);
		requestMessage = MessageBuilder.fromMessage(requestMessage).setReplyChannel(tempReplyChannel)
				.setHeader(this.sendTimeoutHeader, null)
				.setHeader(this.receiveTimeoutHeader, null)
				.setErrorChannel(tempReplyChannel).build();

		try {
			doSend(channel, requestMessage, sendTimeout);
		}
		catch (RuntimeException ex) {
			tempReplyChannel.setSendFailed(true);
			throw ex;
		}

		Message!(T) replyMessage = this.doReceive(tempReplyChannel, receiveTimeout);
		if (replyMessage !is null) {
			replyMessage = MessageBuilder.fromMessage(replyMessage)
					.setHeader(MessageHeaders.REPLY_CHANNEL, originalReplyChannelHeader)
					.setHeader(MessageHeaders.ERROR_CHANNEL, originalErrorChannelHeader)
					.build();
		}

		return replyMessage;
	}

	private long sendTimeout(Message!(T) requestMessage) {
		Long sendTimeout = headerToLong(requestMessage.getHeaders().get(this.sendTimeoutHeader));
		return (sendTimeout !is null ? sendTimeout : this.sendTimeout);
	}

	private long receiveTimeout(Message!(T) requestMessage) {
		Long receiveTimeout = headerToLong(requestMessage.getHeaders().get(this.receiveTimeoutHeader));
		return (receiveTimeout !is null ? receiveTimeout : this.receiveTimeout);
	}

	
	private Long headerToLong(Object headerValue) {
		Number number = cast(Number)headerValue;
		if (number !is null) {
			return number.longValue();
		}
		else {
			auto stringValue = cast(Nullable!string)headerValue;
			if (stringValue !is null) {
				return Long.parseLong(stringValue.value);
			} else {
				return null;
			}

		} 
	}
}




/**
 * A temporary channel for receiving a single reply message.
 */
// private static final class TemporaryReplyChannel : PollableChannel {

//     private final CountDownLatch replyLatch = new CountDownLatch(1);

//     private final bool throwExceptionOnLateReply;

    
//     private Message!(T) replyMessage;

//     private bool hasReceived;

//     private bool hasTimedOut;

//     private bool hasSendFailed;

//     this(bool throwExceptionOnLateReply) {
//         this.throwExceptionOnLateReply = throwExceptionOnLateReply;
//     }

//     void setSendFailed(bool hasSendError) {
//         this.hasSendFailed = hasSendError;
//     }

//     override
    
//     Message!(T) receive() {
//         return this.receive(-1);
//     }

//     override
    
//     Message!(T) receive(long timeout) {
//         try {
//             if (timeout < 0) {
//                 this.replyLatch.await();
//                 this.hasReceived = true;
//             }
//             else {
//                 if (this.replyLatch.await(timeout, TimeUnit.MILLISECONDS)) {
//                     this.hasReceived = true;
//                 }
//                 else {
//                     this.hasTimedOut = true;
//                 }
//             }
//         }
//         catch (InterruptedException ex) {
//             Thread.currentThread().interrupt();
//         }
//         return this.replyMessage;
//     }

//     override
//     bool send(MessageBase message) {
//         return this.send(message, -1);
//     }

//     override
//     bool send(MessageBase message, long timeout) {
//         this.replyMessage = message;
//         bool alreadyReceivedReply = this.hasReceived;
//         this.replyLatch.countDown();

//         string errorDescription = null;
//         if (this.hasTimedOut) {
//             errorDescription = "Reply message received but the receiving thread has exited due to a timeout";
//         }
//         else if (alreadyReceivedReply) {
//             errorDescription = "Reply message received but the receiving thread has already received a reply";
//         }
//         else if (this.hasSendFailed) {
//             errorDescription = "Reply message received but the receiving thread has exited due to " ~
//                     "an exception while sending the request message";
//         }

//         if (errorDescription !is null) {
//             version(HUNT_DEBUG) {
//                 warningf(errorDescription ~ ":" ~ message);
//             }
//             if (this.throwExceptionOnLateReply) {
//                 throw new MessageDeliveryException(message, errorDescription);
//             }
//         }

//         return true;
//     }
// }
