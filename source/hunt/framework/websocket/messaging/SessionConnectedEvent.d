/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
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
