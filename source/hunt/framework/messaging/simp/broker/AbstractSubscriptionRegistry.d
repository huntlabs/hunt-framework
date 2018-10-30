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

module hunt.framework.messaging.simp.broker.AbstractSubscriptionRegistry;

import hunt.container;
import hunt.logging;

import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHeaders;

import hunt.framework.messaging.simp.SimpMessageHeaderAccessor;
import hunt.framework.messaging.simp.SimpMessageType;
// import hunt.framework.util.CollectionUtils;
// import hunt.framework.util.LinkedMultiValueMap;
// import hunt.framework.util.MultiValueMap;

/**
 * Abstract base class for implementations of {@link SubscriptionRegistry} that
 * looks up information in messages but delegates to abstract methods for the
 * actual storage and retrieval.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
abstract class AbstractSubscriptionRegistry : SubscriptionRegistry {

	private __gshared MultiValueMap!(string, string) EMPTY_MAP;

	shared static this() {
		EMPTY_MAP = new LinkedMultiValueMap!(string, string)();
	}


	override
	final void registerSubscription(MessageBase message) {
		MessageHeaders headers = message.getHeaders();

		SimpMessageType messageType = SimpMessageHeaderAccessor.getMessageType(headers);
		if (!SimpMessageType.SUBSCRIBE.equals(messageType)) {
			throw new IllegalArgumentException("Expected SUBSCRIBE: " ~ message);
		}

		string sessionId = SimpMessageHeaderAccessor.getSessionId(headers);
		if (sessionId is null) {
			version(HUNT_DEBUG) {
				error("No sessionId in  " ~ message);
			}
			return;
		}

		string subscriptionId = SimpMessageHeaderAccessor.getSubscriptionId(headers);
		if (subscriptionId is null) {
			version(HUNT_DEBUG) {
				error("No subscriptionId in " ~ message);
			}
			return;
		}

		string destination = SimpMessageHeaderAccessor.getDestination(headers);
		if (destination is null) {
			version(HUNT_DEBUG) {
				error("No destination in " ~ message);
			}
			return;
		}

		addSubscriptionInternal(sessionId, subscriptionId, destination, message);
	}

	override
	final void unregisterSubscription(MessageBase message) {
		MessageHeaders headers = message.getHeaders();

		SimpMessageType messageType = SimpMessageHeaderAccessor.getMessageType(headers);
		if (!SimpMessageType.UNSUBSCRIBE.equals(messageType)) {
			throw new IllegalArgumentException("Expected UNSUBSCRIBE: " ~ message);
		}

		string sessionId = SimpMessageHeaderAccessor.getSessionId(headers);
		if (sessionId is null) {
			version(HUNT_DEBUG) {
				error("No sessionId in " ~ message);
			}
			return;
		}

		string subscriptionId = SimpMessageHeaderAccessor.getSubscriptionId(headers);
		if (subscriptionId is null) {
			version(HUNT_DEBUG) {
				error("No subscriptionId " ~ message);
			}
			return;
		}

		removeSubscriptionInternal(sessionId, subscriptionId, message);
	}

	override
	final MultiValueMap!(string, string) findSubscriptions(MessageBase message) {
		MessageHeaders headers = message.getHeaders();

		SimpMessageType type = SimpMessageHeaderAccessor.getMessageType(headers);
		if (!SimpMessageType.MESSAGE.equals(type)) {
			throw new IllegalArgumentException("Unexpected message type: " ~ type);
		}

		string destination = SimpMessageHeaderAccessor.getDestination(headers);
		if (destination is null) {
			version(HUNT_DEBUG) {
				error("No destination in " ~ message);
			}
			return EMPTY_MAP;
		}

		return findSubscriptionsInternal(destination, message);
	}


	protected abstract void addSubscriptionInternal(
			string sessionId, string subscriptionId, string destination, MessageBase message);

	protected abstract void removeSubscriptionInternal(
			string sessionId, string subscriptionId, MessageBase message);

	protected abstract MultiValueMap!(string, string) findSubscriptionsInternal(
			string destination, MessageBase message);

}
