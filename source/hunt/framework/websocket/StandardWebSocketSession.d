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

module hunt.framework.websocket.StandardWebSocketSession;


// import java.util.Map;
// import javax.websocket.CloseReason;
// import javax.websocket.CloseReason.CloseCodes;
// import javax.websocket.Extension;
// import javax.websocket.Session;

// import hunt.framework.http.HttpHeaders;


// import hunt.framework.util.CollectionUtils;
// import hunt.framework.websocket.BinaryMessage;
// import hunt.framework.websocket.PingMessage;
// import hunt.framework.websocket.PongMessage;
// import hunt.framework.websocket.TextMessage;
// import hunt.framework.websocket.WebSocketExtension;
import hunt.framework.websocket.WebSocketSession;
import hunt.framework.websocket.AbstractWebSocketSession;

import hunt.container;
import hunt.http.codec.http.model.HttpFields;
import hunt.http.codec.http.model.HttpURI;
import hunt.http.codec.websocket.model.CloseStatus;
import hunt.http.codec.websocket.stream.WebSocketConnection;
import hunt.lang.exception;
import hunt.logging;
import hunt.security.Principal;
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
	
	private Principal user;
	
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

		this(headers, attributes, localAddress, remoteAddress, null);
	}

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

		super(attributes);
		this.id = idGenerator.generateId().toString();
		headers = (headers !is null ? headers : new HttpHeaders());
		this.handshakeHeaders = headers;
		this.user = user;
		this.localAddress = localAddress;
		this.remoteAddress = remoteAddress;
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
	// 	assert(this.extensions !is null, "WebSocket session is not yet initialized");
	// 	return this.extensions;
	// }

	Principal getPrincipal() {
		return this.user;
	}

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
		// 	this.extensions = new ArrayList<>(standardExtensions.size());
		// 	for (Extension standardExtension : standardExtensions) {
		// 		this.extensions.add(new StandardToWebSocketExtensionAdapter(standardExtension));
		// 	}
		// 	this.extensions = Collections.unmodifiableList(this.extensions);
		// }
		// else {
		// 	this.extensions = Collections.emptyList();
		// }

		// if (this.user is null) {
		// 	this.user = session.getUserPrincipal();
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
	// 	getNativeSession().getBasicRemote().sendPing(message.getPayload());
	// }

	// override
	// protected void sendPongMessage(PongMessage message) {
	// 	getNativeSession().getBasicRemote().sendPong(message.getPayload());
	// }

	override
	protected void closeInternal(CloseStatus status) {
		getNativeSession().close();
		// getNativeSession().close(new CloseReason(CloseCodes.getCloseCode(status.getCode()), status.getReason()));
	}

}
