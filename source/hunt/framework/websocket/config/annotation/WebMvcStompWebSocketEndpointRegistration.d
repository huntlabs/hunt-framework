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

module hunt.framework.websocket.config.annotation.WebMvcStompWebSocketEndpointRegistration;

import hunt.framework.websocket.config.annotation.StompWebSocketEndpointRegistration;

import hunt.framework.task.TaskScheduler;

// import hunt.framework.util.LinkedMultiValueMap;
// import hunt.framework.util.MultiValueMap;
// import hunt.framework.util.ObjectUtils;
// import hunt.framework.util.StringUtils;
// import hunt.framework.web.HttpRequestHandler;
// import hunt.framework.websocket.WebSocketHandler;
// import hunt.framework.websocket.server.HandshakeHandler;
// import hunt.framework.websocket.server.HandshakeInterceptor;
// import hunt.framework.websocket.server.support.OriginHandshakeInterceptor;
// import hunt.framework.websocket.server.support.WebSocketHttpRequestHandler;
// import hunt.framework.websocket.sockjs.SockJsService;
// import hunt.framework.websocket.sockjs.support.SockJsHttpRequestHandler;
// import hunt.framework.websocket.sockjs.transport.handler.WebSocketTransportHandler;

// import hunt.container;
import hunt.lang.exception;
import hunt.http.server.WebSocketHandler;

/**
 * An abstract base class for configuring STOMP over WebSocket/SockJS endpoints.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class WebMvcStompWebSocketEndpointRegistration : StompWebSocketEndpointRegistration {

	private string[] paths;

	private WebSocketHandler webSocketHandler;

	private TaskScheduler sockJsTaskScheduler;
	
	// private HandshakeHandler handshakeHandler;

	private HandshakeInterceptor[] interceptors;

	private string[] allowedOrigins;

	
	// private SockJsServiceRegistration registration;


	this(string[] paths, WebSocketHandler webSocketHandler, TaskScheduler sockJsTaskScheduler) {

		Assert.notEmpty(paths, "No paths specified");
		assert(webSocketHandler, "WebSocketHandler must not be null");

		this.paths = paths;
		this.webSocketHandler = webSocketHandler;
		this.sockJsTaskScheduler = sockJsTaskScheduler;
	}


	// override
	// StompWebSocketEndpointRegistration setHandshakeHandler(HandshakeHandler handshakeHandler) {
	// 	this.handshakeHandler = handshakeHandler;
	// 	return this;
	// }

	// override
	// StompWebSocketEndpointRegistration addInterceptors(HandshakeInterceptor[] interceptors... ) {
	// 	if (!ObjectUtils.isEmpty(interceptors)) {
	// 		this.interceptors.addAll(Arrays.asList(interceptors));
	// 	}
	// 	return this;
	// }

	override
	StompWebSocketEndpointRegistration setAllowedOrigins(string[] allowedOrigins... ) {
		this.allowedOrigins = [];
		if (!allowedOrigins.empty()) {
			this.allowedOrigins = allowedOrigins;
		}
		return this;
	}

	// override
	// SockJsServiceRegistration withSockJS() {
	// 	// this.registration = new SockJsServiceRegistration();
	// 	// this.registration.setTaskScheduler(this.sockJsTaskScheduler);
	// 	// HandshakeInterceptor[] interceptors = getInterceptors();
	// 	// if (interceptors.length > 0) {
	// 	// 	this.registration.setInterceptors(interceptors);
	// 	// }
	// 	// if (this.handshakeHandler !is null) {
	// 	// 	WebSocketTransportHandler handler = new WebSocketTransportHandler(this.handshakeHandler);
	// 	// 	this.registration.setTransportHandlerOverrides(handler);
	// 	// }
	// 	// if (!this.allowedOrigins.isEmpty()) {
	// 	// 	this.registration.setAllowedOrigins(StringUtils.toStringArray(this.allowedOrigins));
	// 	// }
	// 	// return this.registration;
	// 	implementationMissing(false);
	// 	return null;
	// }

	// protected HandshakeInterceptor[] getInterceptors() {
	// 	List!(HandshakeInterceptor) interceptors = new ArrayList<>(this.interceptors.size() + 1);
	// 	interceptors.addAll(this.interceptors);
	// 	interceptors.add(new OriginHandshakeInterceptor(this.allowedOrigins));
	// 	return interceptors.toArray(new HandshakeInterceptor[0]);
	// }

	final MultiValueMap!(HttpRequestHandler, string) getMappings() {
		MultiValueMap!(HttpRequestHandler, string) mappings = new LinkedMultiValueMap!(HttpRequestHandler, string)();
		// if (this.registration !is null) {
		// 	SockJsService sockJsService = this.registration.getSockJsService();
		// 	for (string path : this.paths) {
		// 		string pattern = (path.endsWith("/") ? path ~ "**" : path ~ "/**");
		// 		SockJsHttpRequestHandler handler = new SockJsHttpRequestHandler(sockJsService, this.webSocketHandler);
		// 		mappings.add(handler, pattern);
		// 	}
		// }
		// else 
		{
			// TODO: Tasks pending completion -@zxp at 10/27/2018, 10:56:17 AM
			// 
			foreach (string path ; this.paths) {
				WebSocketHttpRequestHandler handler;
				// if (this.handshakeHandler !is null) {
				// 	handler = new WebSocketHttpRequestHandler(this.webSocketHandler, this.handshakeHandler);
				// }
				// else 
				{
					handler = new WebSocketHttpRequestHandler(this.webSocketHandler);
				}
				// HandshakeInterceptor[] interceptors = getInterceptors();
				// if (interceptors.length > 0) {
				// 	handler.setHandshakeInterceptors(interceptors);
				// }
				mappings.add(handler, path);
			}
		}
		return mappings;
	}

}
