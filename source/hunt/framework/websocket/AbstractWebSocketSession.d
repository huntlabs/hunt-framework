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

module hunt.framework.websocket.AbstractWebSocketSession;

import hunt.stomp.IdGenerator;
import hunt.http.codec.websocket.model.CloseStatus;
import hunt.framework.websocket.WebSocketSession;

import hunt.collection;
import hunt.Exceptions;
import hunt.logging;
import hunt.util.TypeUtils;

import std.uuid;


/**
 * An abstract base class for implementations of {@link WebSocketSession}.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 * @param <T> the native session type
 */
abstract class AbstractWebSocketSession(T) : WebSocketSession {

	protected __gshared IdGenerator idGenerator; // = new AlternativeJdkIdGenerator();

	private Map!(string, Object) attributes;

	shared static this() {
		idGenerator = new class IdGenerator {
			UUID generateId() {
				return randomUUID();
			}
		};
	}

	private T nativeSession;


	/**
	 * Create a new instance and associate the given attributes with it.
	 * @param attributes attributes from the HTTP handshake to associate with the WebSocket
	 * session; the provided attributes are copied, the original map is not used.
	 */
	this(Map!(string, Object) attributes) {
		this.attributes = new HashMap!(string, Object)(); //  = new ConcurrentHashMap<>();
		if (attributes !is null) {
			this.attributes.putAll(attributes);
		}
	}


	// override
	Map!(string, Object) getAttributes() {
		return this.attributes;
	}

	// override
	T getNativeSession() {
		assert(this.nativeSession !is null, "WebSocket session is not yet initialized");
		return this.nativeSession;
	}

	
	// override
	// <R> R getNativeSession(Class!(R) requiredType) {
	// 	return (requiredType is null || requiredType.isInstance(this.nativeSession) ? (R) this.nativeSession : null);
	// }

	void initializeNativeSession(T session) {
		assert(session, "WebSocket session must not be null");
		this.nativeSession = session;
	}

	protected final void checkNativeSessionInitialized() {
		assert(this.nativeSession !is null, "WebSocket session is not yet initialized");
	}

	// override
	final void sendMessage(WebSocketMessage message) {
		checkNativeSessionInitialized();

		version(HUNT_DEBUG) {
			trace("Sending " ~ message.toString() ~ ", " ~ this.toString());
		}

		// if (message instanceof TextMessage) {
		// 	sendTextMessage((TextMessage) message);
		// }
		// else if (message instanceof BinaryMessage) {
		// 	sendBinaryMessage((BinaryMessage) message);
		// }
		// else if (message instanceof PingMessage) {
		// 	sendPingMessage((PingMessage) message);
		// }
		// else if (message instanceof PongMessage) {
		// 	sendPongMessage((PongMessage) message);
		// }
		// else {
		// 	throw new IllegalStateException("Unexpected WebSocketMessage type: " ~ message);
		// }
	}

	abstract void sendTextMessage(string message);
	abstract void sendBinaryMessage(byte[] message);

	// protected abstract void sendPingMessage(PingMessage message);

	// protected abstract void sendPongMessage(PongMessage message);


	// override
	final void close() {
		close(CloseStatus.NORMAL);
	}

	// override
	final void close(CloseStatus status) {
		checkNativeSessionInitialized();
		version(HUNT_DEBUG) {
			trace("Closing " ~ this.toString());
		}
		closeInternal(status);
	}

	protected abstract void closeInternal(CloseStatus status);


	override
	string toString() {
		if (this.nativeSession !is null) {
			return TypeUtils.getSimpleName(typeid(this)) ~ "[id=" ~ getId() ~ 
				", uri=" ~ getUri().toString() ~ "]";
		}
		else {
			return TypeUtils.getSimpleName(typeid(this)) ~ "[nativeSession=null]";
		}
	}

}
