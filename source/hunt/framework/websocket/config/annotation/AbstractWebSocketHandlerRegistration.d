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

module hunt.framework.websocket.config.annotation.AbstractWebSocketHandlerRegistration;


// import hunt.container;
// import hunt.util.ObjectUtils;
// // import hunt.framework.util.StringUtils;

// import hunt.http.server.WebSocketHandler;
// import hunt.framework.websocket.server.HandshakeHandler;
// import hunt.framework.websocket.server.HandshakeInterceptor;
// import hunt.framework.websocket.server.support.DefaultHandshakeHandler;
// import hunt.framework.websocket.server.support.OriginHandshakeInterceptor;
// // import hunt.framework.websocket.sockjs.SockJsService;
// // import hunt.framework.websocket.sockjs.transport.handler.WebSocketTransportHandler;

// /**
//  * Base class for {@link WebSocketHandlerRegistration WebSocketHandlerRegistrations} that gathers all the configuration
//  * options but allows sub-classes to put together the actual HTTP request mappings.
//  *
//  * @author Rossen Stoyanchev
//  * @author Sebastien Deleuze
//  * @since 4.0
//  * @param <M> the mappings type
//  */
// abstract class AbstractWebSocketHandlerRegistration(M) implements WebSocketHandlerRegistration {

// 	private final MultiValueMap!(WebSocketHandler, string) handlerMap = new LinkedMultiValueMap<>();

	
// 	private HandshakeHandler handshakeHandler;

// 	private final List!(HandshakeInterceptor) interceptors = new ArrayList<>();

// 	private final List!(string) allowedOrigins = new ArrayList<>();

	
// 	private SockJsServiceRegistration sockJsServiceRegistration;


// 	override
// 	WebSocketHandlerRegistration addHandler(WebSocketHandler handler, string... paths) {
// 		assert(handler, "WebSocketHandler must not be null");
// 		Assert.notEmpty(paths, "Paths must not be empty");
// 		this.handlerMap.put(handler, Arrays.asList(paths));
// 		return this;
// 	}

// 	override
// 	WebSocketHandlerRegistration setHandshakeHandler(HandshakeHandler handshakeHandler) {
// 		this.handshakeHandler = handshakeHandler;
// 		return this;
// 	}

	
// 	protected HandshakeHandler getHandshakeHandler() {
// 		return this.handshakeHandler;
// 	}

// 	override
// 	WebSocketHandlerRegistration addInterceptors(HandshakeInterceptor... interceptors) {
// 		if (!ObjectUtils.isEmpty(interceptors)) {
// 			this.interceptors.addAll(Arrays.asList(interceptors));
// 		}
// 		return this;
// 	}

// 	override
// 	WebSocketHandlerRegistration setAllowedOrigins(string... allowedOrigins) {
// 		this.allowedOrigins.clear();
// 		if (!ObjectUtils.isEmpty(allowedOrigins)) {
// 			this.allowedOrigins.addAll(Arrays.asList(allowedOrigins));
// 		}
// 		return this;
// 	}

// 	override
// 	SockJsServiceRegistration withSockJS() {
// 		this.sockJsServiceRegistration = new SockJsServiceRegistration();
// 		HandshakeInterceptor[] interceptors = getInterceptors();
// 		if (interceptors.length > 0) {
// 			this.sockJsServiceRegistration.setInterceptors(interceptors);
// 		}
// 		if (this.handshakeHandler !is null) {
// 			WebSocketTransportHandler transportHandler = new WebSocketTransportHandler(this.handshakeHandler);
// 			this.sockJsServiceRegistration.setTransportHandlerOverrides(transportHandler);
// 		}
// 		if (!this.allowedOrigins.isEmpty()) {
// 			this.sockJsServiceRegistration.setAllowedOrigins(StringUtils.toStringArray(this.allowedOrigins));
// 		}
// 		return this.sockJsServiceRegistration;
// 	}

// 	protected HandshakeInterceptor[] getInterceptors() {
// 		List!(HandshakeInterceptor) interceptors = new ArrayList<>(this.interceptors.size() + 1);
// 		interceptors.addAll(this.interceptors);
// 		interceptors.add(new OriginHandshakeInterceptor(this.allowedOrigins));
// 		return interceptors.toArray(new HandshakeInterceptor[0]);
// 	}

// 	/**
// 	 * Expose the {@code SockJsServiceRegistration} -- if SockJS is enabled or
// 	 * {@code null} otherwise -- so that it can be configured with a TaskScheduler
// 	 * if the application did not provide one. This should be done prior to
// 	 * calling {@link #getMappings()}.
// 	 */
	
// 	protected SockJsServiceRegistration getSockJsServiceRegistration() {
// 		return this.sockJsServiceRegistration;
// 	}

// 	protected final M getMappings() {
// 		M mappings = createMappings();
// 		if (this.sockJsServiceRegistration !is null) {
// 			SockJsService sockJsService = this.sockJsServiceRegistration.getSockJsService();
// 			this.handlerMap.forEach((wsHandler, paths) -> {
// 				for (string path : paths) {
// 					string pathPattern = (path.endsWith("/") ? path ~ "**" : path ~ "/**");
// 					addSockJsServiceMapping(mappings, sockJsService, wsHandler, pathPattern);
// 				}
// 			});
// 		}
// 		else {
// 			HandshakeHandler handshakeHandler = getOrCreateHandshakeHandler();
// 			HandshakeInterceptor[] interceptors = getInterceptors();
// 			this.handlerMap.forEach((wsHandler, paths) -> {
// 				for (string path : paths) {
// 					addWebSocketHandlerMapping(mappings, wsHandler, handshakeHandler, interceptors, path);
// 				}
// 			});
// 		}

// 		return mappings;
// 	}

// 	private HandshakeHandler getOrCreateHandshakeHandler() {
// 		return (this.handshakeHandler !is null ? this.handshakeHandler : new DefaultHandshakeHandler());
// 	}


// 	protected abstract M createMappings();

// 	protected abstract void addSockJsServiceMapping(M mappings, SockJsService sockJsService,
// 			WebSocketHandler handler, string pathPattern);

// 	protected abstract void addWebSocketHandlerMapping(M mappings, WebSocketHandler wsHandler,
// 			HandshakeHandler handshakeHandler, HandshakeInterceptor[] interceptors, string path);

// }
