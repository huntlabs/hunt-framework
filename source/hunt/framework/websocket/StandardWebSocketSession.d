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

module hunt.framework.websocket.StandardWebSocketSession;


// import java.util.Map;
// import javax.websocket.CloseReason;
// import javax.websocket.CloseReason.CloseCodes;
// import javax.websocket.Extension;
// import javax.websocket.Session;

// import hunt.framework.util.CollectionUtils;
// import hunt.framework.websocket.BinaryMessage;
// import hunt.framework.websocket.PingMessage;
// import hunt.framework.websocket.PongMessage;
// import hunt.framework.websocket.TextMessage;
// import hunt.framework.websocket.WebSocketExtension;
import hunt.framework.websocket.WebSocketSession;
import hunt.framework.websocket.AbstractWebSocketSession;

import hunt.collection;
import hunt.http.codec.http.model.HttpFields;
import hunt.http.codec.http.model.HttpURI;
import hunt.http.codec.websocket.model.CloseStatus;
import hunt.http.codec.websocket.stream.WebSocketConnection;
import hunt.Exceptions;
import hunt.logging;

version(Have_hunt_security) {
    import hunt.security.Principal;
}

import std.socket;

alias HttpHeaders = HttpFields;

/**
 * A {@link WebSocketSession} for use with the standard WebSocket for Java API.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class StandardWebSocketSession : AbstractWebSocketSession!(WebSocketConnection) {

    private string id;

    private HttpURI uri;

    private HttpHeaders handshakeHeaders;

    private string acceptedProtocol;

    // private List!(WebSocketExtension) extensions;

    version(Have_hunt_security) private Principal user;

    private Address localAddress;

    private Address remoteAddress;


    /**
     * Constructor for a standard WebSocket session.
     * @param headers the headers of the handshake request
     * @param attributes attributes from the HTTP handshake to associate with the WebSocket
     * session; the provided attributes are copied, the original map is not used.
     * @param localAddress the address on which the request was received
     * @param remoteAddress the address of the remote client
     */
    this(HttpHeaders headers, Map!(string, Object) attributes,
            Address localAddress, Address remoteAddress) {
        super(attributes);
        this.id = idGenerator.generateId().toString();
        headers = (headers !is null ? headers : new HttpHeaders());
        this.handshakeHeaders = headers;
        this.localAddress = localAddress;
        this.remoteAddress = remoteAddress;
    }

version(Have_hunt_security) {

    /**
     * Constructor that associates a user with the WebSocket session.
     * @param headers the headers of the handshake request
     * @param attributes attributes from the HTTP handshake to associate with the WebSocket session
     * @param localAddress the address on which the request was received
     * @param remoteAddress the address of the remote client
     * @param user the user associated with the session; if {@code null} we'll
     * fallback on the user available in the underlying WebSocket session
     */
    this(HttpHeaders headers, Map!(string, Object) attributes,
            Address localAddress, Address remoteAddress, Principal user) {
        this(headers, attributes, localAddress, remoteAddress, null);
        this.user = user;
    }


    Principal getPrincipal() {
        return this.user;
    }
}

    // override
    string getId() {
        return this.id;
    }

    // override
    HttpURI getUri() {
        checkNativeSessionInitialized();
        return this.uri;
    }

    // override
    HttpHeaders getHandshakeHeaders() {
        return this.handshakeHeaders;
    }

    // override
    string getAcceptedProtocol() {
        checkNativeSessionInitialized();
        return this.acceptedProtocol;
    }

    // override
    // List!(WebSocketExtension) getExtensions() {
    //     assert(this.extensions !is null, "WebSocket session is not yet initialized");
    //     return this.extensions;
    // }

    // override
    Address getLocalAddress() {
        return this.localAddress;
    }

    // override
    Address getRemoteAddress() {
        return this.remoteAddress;
    }

    // override
    void setTextMessageSizeLimit(int messageSizeLimit) {
        checkNativeSessionInitialized();
        // getNativeSession().setMaxTextMessageBufferSize(messageSizeLimit);
        implementationMissing(false);
    }

    // override
    int getTextMessageSizeLimit() {
        checkNativeSessionInitialized();
        // return getNativeSession().getMaxTextMessageBufferSize();
        implementationMissing(false);
        return 0;
    }

    // override
    void setBinaryMessageSizeLimit(int messageSizeLimit) {
        checkNativeSessionInitialized();
        // getNativeSession().setMaxBinaryMessageBufferSize(messageSizeLimit);

        implementationMissing(false);
    }

    // override
    int getBinaryMessageSizeLimit() {
        checkNativeSessionInitialized();
        // return getNativeSession().getMaxBinaryMessageBufferSize();
        implementationMissing(false);
        return 0;
    }

    // override
    bool isOpen() {
        return getNativeSession().isOpen();
    }

    override
    void initializeNativeSession(WebSocketConnection session) {
        super.initializeNativeSession(session);

        this.uri = session.getUpgradeRequest().getURI();
        // TODO: Tasks pending completion -@zxp at 11/4/2018, 10:15:44 AM
        // 
        // this.acceptedProtocol = session.getNegotiatedSubprotocol();
        this.acceptedProtocol = "";

        // List!(Extension) standardExtensions = getNativeSession().getNegotiatedExtensions();
        // if (!CollectionUtils.isEmpty(standardExtensions)) {
        //     this.extensions = new ArrayList<>(standardExtensions.size());
        //     for (Extension standardExtension : standardExtensions) {
        //         this.extensions.add(new StandardToWebSocketExtensionAdapter(standardExtension));
        //     }
        //     this.extensions = Collections.unmodifiableList(this.extensions);
        // }
        // else {
        //     this.extensions = Collections.emptyList();
        // }

        // if (this.user is null) {
        //     this.user = session.getUserPrincipal();
        // }
    }

    override
    void sendTextMessage(string message) {
        // getNativeSession().getBasicRemote().sendText(message.getPayload(), message.isLast());
        getNativeSession().sendText(message);

    }

    override
    void sendBinaryMessage(byte[] message) {
        // getNativeSession().getBasicRemote().sendBinary(message.getPayload(), message.isLast());
        getNativeSession().sendData(message);
    }

    // override
    // protected void sendPingMessage(PingMessage message) {
    //     getNativeSession().getBasicRemote().sendPing(message.getPayload());
    // }

    // override
    // protected void sendPongMessage(PongMessage message) {
    //     getNativeSession().getBasicRemote().sendPong(message.getPayload());
    // }

    override
    protected void closeInternal(CloseStatus status) {
        getNativeSession().close();
        // getNativeSession().close(new CloseReason(CloseCodes.getCloseCode(status.getCode()), status.getReason()));
    }

}
