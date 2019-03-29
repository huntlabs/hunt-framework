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

module hunt.framework.websocket.messaging.SessionDisconnectEvent;

import hunt.framework.websocket.messaging.AbstractSubProtocolEvent;
import hunt.stomp.Message;

version(Have_hunt_security) {
    import hunt.security.Principal;
}

import hunt.http.codec.websocket.model.CloseStatus;

/**
 * Event raised when the session of a WebSocket client using a Simple Messaging
 * Protocol (e.g. STOMP) as the WebSocket sub-protocol is closed.
 *
 * <p>Note that this event may be raised more than once for a single session and
 * therefore event consumers should be idempotent and ignore a duplicate event.
 *
 * @author Rossen Stoyanchev
 * @since 4.0.3
 */

class SessionDisconnectEvent : AbstractSubProtocolEvent {

    private string sessionId;

    private CloseStatus status;


    /**
     * Create a new SessionDisconnectEvent.
     * @param source the component that published the event (never {@code null})
     * @param message the message (never {@code null})
     * @param sessionId the disconnect message
     * @param closeStatus the status object
     */
    this(Object source, Message!(byte[]) message, string sessionId,
            CloseStatus closeStatus) {
        super(source, message);
        assert(sessionId, "Session id must not be null");
        this.sessionId = sessionId;
        this.status = closeStatus;
    }

version(Have_hunt_security) {
    /**
     * Create a new SessionDisconnectEvent.
     * @param source the component that published the event (never {@code null})
     * @param message the message (never {@code null})
     * @param sessionId the disconnect message
     * @param closeStatus the status object
     * @param user the current session user
     */
    this(Object source, Message!(byte[]) message, string sessionId,
            CloseStatus closeStatus, Principal user) {
        super(source, message, user);
        assert(sessionId, "Session id must not be null");
        this.sessionId = sessionId;
        this.status = closeStatus;
    }
}

    /**
     * Return the session id.
     */
    string getSessionId() {
        return this.sessionId;
    }

    /**
     * Return the status with which the session was closed.
     */
    CloseStatus getCloseStatus() {
        return this.status;
    }


    override
    string toString() {
        return "SessionDisconnectEvent[sessionId=" ~ this.sessionId ~ 
            ", " ~ this.status.toString() ~ "]";
    }

}
