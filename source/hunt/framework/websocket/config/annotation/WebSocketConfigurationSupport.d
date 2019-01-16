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

module hunt.framework.websocket.config.annotation.WebSocketConfigurationSupport;

// import hunt.framework.websocket.config.annotation.ServletWebSocketHandlerRegistry;
// import hunt.framework.context.annotation.Bean;

import hunt.framework.task.TaskScheduler;
// import hunt.framework.scheduling.concurrent.ThreadPoolTaskScheduler;

// import hunt.framework.web.servlet.HandlerMapping;

/**
 * Configuration support for WebSocket request handling.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
// class WebSocketConfigurationSupport {

	
// 	private ServletWebSocketHandlerRegistry handlerRegistry;

	
// 	private TaskScheduler scheduler;


	
// 	HandlerMapping webSocketHandlerMapping() {
// 		ServletWebSocketHandlerRegistry registry = initHandlerRegistry();
// 		if (registry.requiresTaskScheduler()) {
// 			// TaskScheduler scheduler = defaultSockJsTaskScheduler();
// 			// assert(scheduler, "Expected default TaskScheduler bean");
// 			// registry.setTaskScheduler(scheduler);
// 		}
// 		return registry.getHandlerMapping();
// 	}

// 	private ServletWebSocketHandlerRegistry initHandlerRegistry() {
// 		if (this.handlerRegistry is null) {
// 			this.handlerRegistry = new ServletWebSocketHandlerRegistry();
// 			registerWebSocketHandlers(this.handlerRegistry);
// 		}
// 		return this.handlerRegistry;
// 	}

// 	protected void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
// 	}

// 	/**
// 	 * The default TaskScheduler to use if none is registered explicitly via
// 	 * {@link SockJsServiceRegistration#setTaskScheduler}:
// 	 * <pre class="code">
// 	 * &#064;Configuration
// 	 * &#064;EnableWebSocket
// 	 * class WebSocketConfig implements WebSocketConfigurer {
// 	 *
// 	 *   void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
// 	 *     registry.addHandler(myHandler(), "/echo")
// 	 *             .withSockJS()
// 	 *             .setTaskScheduler(myScheduler());
// 	 *   }
// 	 *
// 	 *   // ...
// 	 * }
// 	 * </pre>
// 	 */
	
	
// 	// TaskScheduler defaultSockJsTaskScheduler() {
// 	// 	if (initHandlerRegistry().requiresTaskScheduler()) {
// 	// 		ThreadPoolTaskScheduler threadPoolScheduler = new ThreadPoolTaskScheduler();
// 	// 		threadPoolScheduler.setThreadNamePrefix("SockJS-");
// 	// 		threadPoolScheduler.setPoolSize(Runtime.getRuntime().availableProcessors());
// 	// 		threadPoolScheduler.setRemoveOnCancelPolicy(true);
// 	// 		this.scheduler = threadPoolScheduler;
// 	// 	}
// 	// 	return this.scheduler;
// 	// }

// }
