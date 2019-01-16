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

module hunt.framework.websocket.config.annotation.WebSocketHandlerRegistry;

import hunt.framework.websocket.config.annotation.WebSocketHandlerRegistration;

import hunt.http.server.WebSocketHandler;

/**
 * Provides methods for configuring {@link WebSocketHandler} request mappings.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
interface WebSocketHandlerRegistry {

	/**
	 * Configure a WebSocketHandler at the specified URL paths.
	 */
	WebSocketHandlerRegistration addHandler(WebSocketHandler webSocketHandler, string[] paths...);

}
