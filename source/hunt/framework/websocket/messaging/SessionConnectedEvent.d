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

module hunt.framework.websocket.messaging.SessionConnectedEvent;

import hunt.framework.websocket.messaging.AbstractSubProtocolEvent;
import hunt.stomp.Message;

import hunt.security.Principal;


/**
 * A connected event represents the server response to a client's connect request.
 * See {@link hunt.framework.websocket.messaging.SessionConnectEvent}.
 *
 * @author Rossen Stoyanchev
 * @since 4.0.3
 */

class SessionConnectedEvent : AbstractSubProtocolEvent {

	/**
	 * Create a new SessionConnectedEvent.
	 * @param source the component that published the event (never {@code null})
	 * @param message the connected message (never {@code null})
	 */
	this(Object source, Message!(byte[]) message) {
		super(source, message);
	}

	this(Object source, Message!(byte[]) message, Principal user) {
		super(source, message, user);
	}

}
