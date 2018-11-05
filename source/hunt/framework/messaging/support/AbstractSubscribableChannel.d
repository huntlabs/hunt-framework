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

import hunt.container;
import hunt.logging;
import std.conv;
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
		handlers = new HashSet!(MessageHandler)(); //  new CopyOnWriteArraySet!(MessageHandler)();
	}


	Set!(MessageHandler) getSubscribers() {
		trace("vvv=>>>>>>", id);
		return this.handlers; // Collections.unmodifiableSet!(MessageHandler)
	}

	bool hasSubscription(MessageHandler handler) {
		return this.handlers.contains(handler);
	}

	override
	bool subscribe(MessageHandler handler) {
		bool result = this.handlers.add(handler);
		version(HUNT_DEBUG) {
			if (result) 
				trace(getBeanName() ~ " added " ~ handler.to!string());
		}

		tracef("xxxx=>%s, %d", id, this.handlers.size);
		
		return result;
	}

	override
	bool unsubscribe(MessageHandler handler) {

		trace("xxxxxxxxxxxxxx");
		bool result = this.handlers.remove(handler);
		version(HUNT_DEBUG) {
			if (result)
				trace(getBeanName() ~ " removed " ~ handler.to!string());
		}
		return result;
	}

}
