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

module hunt.framework.websocket.config.annotation.WebSocketConfigurer;

import hunt.framework.websocket.config.annotation.WebSocketHandlerRegistry;
import hunt.http.server.WebSocketHandler;

/**
 * Defines callback methods to configure the WebSocket request handling
 * via {@link hunt.framework.websocket.config.annotation.EnableWebSocket @EnableWebSocket}.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
interface WebSocketConfigurer {

	/**
	 * Register {@link WebSocketHandler WebSocketHandlers} including SockJS fallback options if desired.
	 */
	void registerWebSocketHandlers(WebSocketHandlerRegistry registry);

}
