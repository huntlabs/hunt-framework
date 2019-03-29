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

module hunt.framework.websocket.messaging.AbstractSubProtocolEvent;

import hunt.framework.application.ApplicationEvent;
import hunt.stomp.Message;

version(Have_hunt_security) {
    import hunt.security.Principal;
}

import hunt.util.TypeUtils;

import std.conv;

/**
 * A base class for events for a message received from a WebSocket client and
 * parsed into a higher-level sub-protocol (e.g. STOMP).
 *
 * @author Rossen Stoyanchev
 * @since 4.1
 */

abstract class AbstractSubProtocolEvent : ApplicationEvent {

    private Message!(byte[]) message;


    /**
     * Create a new AbstractSubProtocolEvent.
     * @param source the component that published the event (never {@code null})
     * @param message the incoming message (never {@code null})
     */
    protected this(Object source, Message!(byte[]) message) {
        super(source);
        assert(message, "Message must not be null");
        this.message = message;
    }

version(Have_hunt_security) {
    /**
     * Create a new AbstractSubProtocolEvent.
     * @param source the component that published the event (never {@code null})
     * @param message the incoming message (never {@code null})
     */
    protected this(Object source, Message!(byte[]) message, Principal user) { 
        this(source, message);
        this.user = user;
    }


    /**
     * Return the user for the session associated with the event.
     */

    Principal getUser() {
        return this.user;
    }

    private Principal user;
}

    /**
     * Return the Message associated with the event. Here is an example of
     * obtaining information about the session id or any headers in the
     * message:
     * <pre class="code">
     * StompHeaderAccessor headers = StompHeaderAccessor.wrap(message);
     * headers.getSessionId();
     * headers.getSessionAttributes();
     * headers.getPrincipal();
     * </pre>
     */
    Message!(byte[]) getMessage() {
        return this.message;
    }


    override
    string toString() {
        return TypeUtils.getSimpleName(typeid(this)) ~ " [" ~ this.message.to!string() ~ "]";
    }

}
