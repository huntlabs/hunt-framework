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

module hunt.framework.messaging.simp.broker;

import hunt.framework.messaging.Message;
import hunt.framework.util.MultiValueMap;

/**
 * A registry of subscription by session that allows looking up subscriptions.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
interface SubscriptionRegistry {

	/**
	 * Register a subscription represented by the given message.
	 * @param subscribeMessage the subscription request
	 */
	void registerSubscription(MessageBase subscribeMessage);

	/**
	 * Unregister a subscription.
	 * @param unsubscribeMessage the request to unsubscribe
	 */
	void unregisterSubscription(MessageBase unsubscribeMessage);

	/**
	 * Remove all subscriptions associated with the given sessionId.
	 */
	void unregisterAllSubscriptions(string sessionId);

	/**
	 * Find all subscriptions that should receive the given message.
	 * The map returned is safe to iterate and will never be modified.
	 * @param message the message
	 * @return a {@code MultiValueMap} with sessionId-subscriptionId pairs
	 * (possibly empty)
	 */
	MultiValueMap!(string, string) findSubscriptions(MessageBase message);

}
