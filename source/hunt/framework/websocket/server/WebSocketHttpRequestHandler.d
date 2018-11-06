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

module hunt.framework.websocket.server.WebSocketHttpRequestHandler;

// import java.io.IOException;
// import java.util.ArrayList;
// import java.util.HashMap;
// import java.util.List;
// import java.util.Map;
// import javax.servlet.ServletContext;
// import javax.servlet.ServletException;
// import javax.servlet.http.HttpServletRequest;
// import javax.servlet.http.HttpServletResponse;

import hunt.container;
import hunt.logging;


// import hunt.framework.web.HttpRequestHandler;
// import hunt.framework.web.context.ServletContextAware;
// import hunt.framework.websocket.handler.ExceptionWebSocketHandlerDecorator;
// import hunt.framework.websocket.handler.LoggingWebSocketHandlerDecorator;
// import hunt.framework.websocket.server.HandshakeFailureException;
// import hunt.framework.websocket.server.HandshakeHandler;
// import hunt.framework.websocket.server.HandshakeInterceptor;

import hunt.framework.websocket.StandardWebSocketSession;
import hunt.framework.websocket.WebSocketMessageHandler;
// import hunt.http.codec.http.model.MetaData;
import hunt.http.codec.http.model;
import hunt.http.codec.http.stream;
import hunt.http.codec.websocket.frame.Frame;
import hunt.http.codec.websocket.frame.WebSocketFrame;
import hunt.http.codec.websocket.model.CloseStatus;
import hunt.http.codec.websocket.stream.WebSocketConnection;

import hunt.http.server.WebSocketHandler;

/**
 * A {@link HttpRequestHandler} for processing WebSocket handshake requests.
 *
 * <p>This is the main class to use when configuring a server WebSocket at a specific URL.
 * It is a very thin wrapper around a {@link WebSocketHandler} and a {@link HandshakeHandler},
 * also adapting the {@link HttpServletRequest} and {@link HttpServletResponse} to
 * {@link ServerHttpRequest} and {@link ServerHttpResponse}, respectively.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class WebSocketHttpRequestHandler : WebSocketHandler { // , Lifecycle, ServletContextAware 


	private WebSocketMessageHandler wsHandler;
	private StandardWebSocketSession wsSession;

	// private HandshakeHandler handshakeHandler;

	// private List!(HandshakeInterceptor) interceptors = new ArrayList<>();

	private bool running = false;


	this(WebSocketMessageHandler wsHandler) {
		// this(wsHandler, new DefaultHandshakeHandler());
		this.wsHandler = wsHandler; 
	}

	// this(WebSocketMessageHandler wsHandler, HandshakeHandler handshakeHandler) {
	// 	assert(wsHandler, "wsHandler must not be null");
	// 	assert(handshakeHandler, "handshakeHandler must not be null");
	// 	this.wsHandler = wsHandler; // new ExceptionWebSocketHandlerDecorator(new LoggingWebSocketHandlerDecorator(wsHandler));
	// 	this.handshakeHandler = handshakeHandler;
	// }


	/**
	 * Return the WebSocketHandler.
	 */
	WebSocketMessageHandler getWebSocketHandler() {
		return this.wsHandler;
	}

	/**
	 * Return the HandshakeHandler.
	 */
	// HandshakeHandler getHandshakeHandler() {
	// 	return this.handshakeHandler;
	// }

	/**
	 * Configure one or more WebSocket handshake request interceptors.
	 */
	// void setHandshakeInterceptors(List!(HandshakeInterceptor) interceptors) {
	// 	this.interceptors.clear();
	// 	if (interceptors !is null) {
	// 		this.interceptors.addAll(interceptors);
	// 	}
	// }

	/**
	 * Return the configured WebSocket handshake request interceptors.
	 */
	// List!(HandshakeInterceptor) getHandshakeInterceptors() {
	// 	return this.interceptors;
	// }

	// override
	// void setServletContext(ServletContext servletContext) {
	// 	if (this.handshakeHandler instanceof ServletContextAware) {
	// 		((ServletContextAware) this.handshakeHandler).setServletContext(servletContext);
	// 	}
	// }


	// override
	// void start() {
	// 	if (!isRunning()) {
	// 		this.running = true;
	// 		if (this.handshakeHandler instanceof Lifecycle) {
	// 			((Lifecycle) this.handshakeHandler).start();
	// 		}
	// 	}
	// }

	// override
	// void stop() {
	// 	if (isRunning()) {
	// 		this.running = false;
	// 		if (this.handshakeHandler instanceof Lifecycle) {
	// 			((Lifecycle) this.handshakeHandler).stop();
	// 		}
	// 	}
	// }

	// override
	bool isRunning() {
		return this.running;
	}

	override void onConnect(WebSocketConnection session) {
		version(HUNT_DEBUG)
		info("WebSocket connection on: ", session.getUpgradeRequest.getURI.toString());

		this.wsSession.initializeNativeSession(session);
		this.wsHandler.afterConnectionEstablished(this.wsSession);
	}

	override void onFrame(Frame frame, WebSocketConnection connection) {
		this.wsHandler.handleMessage(this.wsSession, cast(WebSocketFrame)frame);
	}

	override void onError(Exception t, WebSocketConnection connection) {
		this.wsHandler.handleTransportError(this.wsSession, t);
	}

	override
	bool acceptUpgrade(HttpRequest request, HttpResponse response, 
            HttpOutputStream output, HttpConnection connection) {

		// HandshakeInterceptorChain chain = new HandshakeInterceptorChain(this.interceptors, this.wsHandler);
		// HandshakeFailureException failure = null;

		try {
			version(HUNT_DEBUG) { 
				info("Upgrade handshaking...");
				trace(request.getMethod() ~ " " ~ request.getURIString());
			}

			wsSession = new StandardWebSocketSession(request.getFields(), null,
				connection.getLocalAddress(), connection.getRemoteAddress(), null); // user

			// Map!(string, Object) attributes = new HashMap<>();
			// if (!chain.applyBeforeHandshake(request, response, attributes)) {
			// 	return;
			// }
			// this.handshakeHandler.doHandshake(request, response, this.wsHandler, attributes);
			// chain.applyAfterHandshake(request, response, null);
			// response.close();
		}
		// catch (HandshakeFailureException ex) {
		// 	failure = ex;
		// }
		catch (Throwable ex) {
			errorf("Uncaught failure for request " ~ request.getURI().toString() ~ "\n", ex);
			// failure = new HandshakeFailureException("Uncaught failure for request " ~ request.getURI(), ex);
		}
		finally {
			// if (failure !is null) {
			// 	chain.applyAfterHandshake(request, response, failure);
			// 	throw failure;
			// }
		}

		return true;
	}
	

}
