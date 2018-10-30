/*
 * Copyright 2002-2016 the original author or authors.
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

module hunt.framework.messaging.support.AbstractSubscribableChannel;

import hunt.framework.messaging.support.AbstractMessageChannel;
import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageChannel;

import hunt.container.Collections;
import hunt.container.Set;
// import java.util.concurrent.CopyOnWriteArraySet;

/**
 * Abstract base class for {@link SubscribableChannel} implementations.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
abstract class AbstractSubscribableChannel : AbstractMessageChannel, SubscribableChannel {

	private Set!(MessageHandler) handlers;

	this() {
		handlers = new CopyOnWriteArraySet!(MessageHandler)();
	}


	Set!(MessageHandler) getSubscribers() {
		return Collections.unmodifiableSet!(MessageHandler)(this.handlers);
	}

	bool hasSubscription(MessageHandler handler) {
		return this.handlers.contains(handler);
	}

	override
	bool subscribe(MessageHandler handler) {
		 result = this.handlers.add(handler);
		if (result) {
			version(HUNT_DEBUG) {
				trace(getBeanName() ~ " added " ~ handler);
			}
		}
		return result;
	}

	override
	bool unsubscribe(MessageHandler handler) {
		 result = this.handlers.remove(handler);
		if (result) {
			version(HUNT_DEBUG) {
				trace(getBeanName() ~ " removed " ~ handler);
			}
		}
		return result;
	}

}
