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

module hunt.framework.websocket.messaging.SessionSubscribeEvent;

import hunt.framework.websocket.messaging.AbstractSubProtocolEvent;

version(Have_hunt_security) {
    import hunt.security.Principal;
}

import hunt.stomp.Message;

/**
 * Event raised when a new WebSocket client using a Simple Messaging Protocol
 * (e.g. STOMP) sends a subscription request.
 *
 * @author Rossen Stoyanchev
 * @since 4.0.3
 */

class SessionSubscribeEvent : AbstractSubProtocolEvent {

    this(Object source, Message!(byte[]) message) {
        super(source, message);
    }

    version(Have_hunt_security) 
    this(Object source, Message!(byte[]) message, Principal user) {
        super(source, message, user);
    }

}
