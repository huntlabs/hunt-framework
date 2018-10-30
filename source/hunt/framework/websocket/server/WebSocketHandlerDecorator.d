/*
 * Copyright 2002-2013 the original author or authors.
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

module hunt.framework.websocket.server.WebSocketHandlerDecorator;

import hunt.http.codec.websocket.model.CloseStatus;
import hunt.http.server.WebSocketHandler;
// import hunt.framework.websocket.WebSocketMessage;
// import hunt.framework.websocket.WebSocketSession;

/**
 * Wraps another {@link hunt.framework.websocket.WebSocketHandler}
 * instance and delegates to it.
 *
 * <p>Also provides a {@link #getDelegate()} method to return the decorated
 * handler as well as a {@link #getLastHandler()} method to go through all nested
 * delegates and return the "last" handler.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
// class WebSocketHandlerDecorator : WebSocketHandler {

// 	private final WebSocketHandler delegate;


// 	WebSocketHandlerDecorator(WebSocketHandler delegate) {
// 		assert(delegate, "Delegate must not be null");
// 		this.delegate = delegate;
// 	}


// 	WebSocketHandler getDelegate() {
// 		return this.delegate;
// 	}

// 	WebSocketHandler getLastHandler() {
// 		WebSocketHandler result = this.delegate;
// 		while (result instanceof WebSocketHandlerDecorator) {
// 			result = ((WebSocketHandlerDecorator) result).getDelegate();
// 		}
// 		return result;
// 	}

// 	static WebSocketHandler unwrap(WebSocketHandler handler) {
// 		if (handler instanceof WebSocketHandlerDecorator) {
// 			return ((WebSocketHandlerDecorator) handler).getLastHandler();
// 		}
// 		else {
// 			return handler;
// 		}
// 	}

// 	override
// 	void afterConnectionEstablished(WebSocketSession session) throws Exception {
// 		this.delegate.afterConnectionEstablished(session);
// 	}

// 	override
// 	void handleMessage(WebSocketSession session, WebSocketMessage<?> message) throws Exception {
// 		this.delegate.handleMessage(session, message);
// 	}

// 	override
// 	void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
// 		this.delegate.handleTransportError(session, exception);
// 	}

// 	override
// 	void afterConnectionClosed(WebSocketSession session, CloseStatus closeStatus) throws Exception {
// 		this.delegate.afterConnectionClosed(session, closeStatus);
// 	}

// 	override
// 	boolsupportsPartialMessages() {
// 		return this.delegate.supportsPartialMessages();
// 	}

// 	override
// 	string toString() {
// 		return TypeUtils.getSimpleName(typeid(this)) ~ " [delegate=" ~ this.delegate ~ "]";
// 	}

// }



/**
 * A factory for applying decorators to a WebSocketHandler.
 *
 * <p>Decoration should be done through sub-classing
 * {@link hunt.framework.websocket.handler.WebSocketHandlerDecorator
 * WebSocketHandlerDecorator} to allow any code to traverse decorators and/or
 * unwrap the original handler when necessary .
 *
 * @author Rossen Stoyanchev
 * @since 4.1.2
 */
interface WebSocketHandlerDecoratorFactory {

	/**
	 * Decorate the given WebSocketHandler.
	 * @param handler the handler to be decorated.
	 * @return the same handler or the handler wrapped with a sub-class of
	 * {@code WebSocketHandlerDecorator}.
	 */
	WebSocketHandler decorate(WebSocketHandler handler);

}
