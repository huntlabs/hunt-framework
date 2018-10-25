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

module hunt.framework.messaging.simp.broker.BrokerAvailabilityEvent;

import hunt.framework.context.ApplicationEvent;
import std.conv;

/**
 * Event raised when a broker's availability changes.
 *
 * @author Andy Wilkinson
 */
class BrokerAvailabilityEvent : ApplicationEvent {

	private bool brokerAvailable;


	/**
	 * Creates a new {@code BrokerAvailabilityEvent}.
	 *
	 * @param brokerAvailable {@code true} if the broker is available, {@code}
	 * false otherwise
	 * @param source the component that is acting as the broker, or as a relay
	 * for an external broker, that has changed availability. Must not be {@code
	 * null}.
	 */
	this(bool brokerAvailable, Object source) {
		super(source);
		this.brokerAvailable = brokerAvailable;
	}

	bool isBrokerAvailable() {
		return this.brokerAvailable;
	}

	override
	string toString() {
		return "BrokerAvailabilityEvent[available=" ~ this.brokerAvailable.to!string()
			 ~ ", " ~ getSource().toString() ~ "]";
	}

}
