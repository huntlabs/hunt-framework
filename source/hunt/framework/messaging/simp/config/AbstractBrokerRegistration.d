/*
 * Copyright 2002-2017 the original author or authors.
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

module hunt.framework.messaging.simp.config;

import java.util.Arrays;
import hunt.container.Collection;
import hunt.container.Collections;
import java.util.List;


import hunt.framework.messaging.MessageChannel;
import hunt.framework.messaging.SubscribableChannel;
import hunt.framework.messaging.simp.broker.AbstractBrokerMessageHandler;


/**
 * Base class for message broker registration classes.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
abstract class AbstractBrokerRegistration {

	private final SubscribableChannel clientInboundChannel;

	private final MessageChannel clientOutboundChannel;

	private final List!(string) destinationPrefixes;


	public AbstractBrokerRegistration(SubscribableChannel clientInboundChannel,
			MessageChannel clientOutboundChannel, string[] destinationPrefixes) {

		assert(clientOutboundChannel, "'clientInboundChannel' must not be null");
		assert(clientOutboundChannel, "'clientOutboundChannel' must not be null");

		this.clientInboundChannel = clientInboundChannel;
		this.clientOutboundChannel = clientOutboundChannel;

		this.destinationPrefixes = (destinationPrefixes !is null ?
				Arrays.asList(destinationPrefixes) : Collections.emptyList());
	}


	protected SubscribableChannel getClientInboundChannel() {
		return this.clientInboundChannel;
	}

	protected MessageChannel getClientOutboundChannel() {
		return this.clientOutboundChannel;
	}

	protected Collection!(string) getDestinationPrefixes() {
		return this.destinationPrefixes;
	}


	protected abstract AbstractBrokerMessageHandler getMessageHandler(SubscribableChannel brokerChannel);

}
