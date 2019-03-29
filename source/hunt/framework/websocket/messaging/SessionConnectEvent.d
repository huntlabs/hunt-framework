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

module hunt.framework.websocket.messaging.SessionConnectEvent;

import hunt.framework.websocket.messaging.AbstractSubProtocolEvent;
import hunt.stomp.Message;

version(Have_hunt_security) {
    import hunt.security.Principal;
}


/**
 * Event raised when a new WebSocket client using a Simple Messaging Protocol
 * (e.g. STOMP) as the WebSocket sub-protocol issues a connect request.
 *
 * <p>Note that this is not the same as the WebSocket session getting established
 * but rather the client's first attempt to connect within the sub-protocol,
 * for example sending the STOMP CONNECT frame.
 *
 * @author Rossen Stoyanchev
 * @since 4.0.3
 */

class SessionConnectEvent : AbstractSubProtocolEvent {

    /**
     * Create a new SessionConnectEvent.
     * @param source the component that published the event (never {@code null})
     * @param message the connect message
     */
    this(Object source, Message!(byte[]) message) {
        super(source, message);
    }

    
    version(Have_hunt_security)
    this(Object source, Message!(byte[]) message, Principal user) {
        super(source, message, user);
    }

}
