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

module hunt.framework.websocket.config.annotation.WebSocketConfigurationSupport;
import hunt.framework.websocket.config.annotation.ServletWebSocketHandlerRegistry;

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
class WebSocketConfigurationSupport {

	
	private ServletWebSocketHandlerRegistry handlerRegistry;

	
	private TaskScheduler scheduler;


	
	HandlerMapping webSocketHandlerMapping() {
		ServletWebSocketHandlerRegistry registry = initHandlerRegistry();
		if (registry.requiresTaskScheduler()) {
			TaskScheduler scheduler = defaultSockJsTaskScheduler();
			assert(scheduler, "Expected default TaskScheduler bean");
			registry.setTaskScheduler(scheduler);
		}
		return registry.getHandlerMapping();
	}

	private ServletWebSocketHandlerRegistry initHandlerRegistry() {
		if (this.handlerRegistry is null) {
			this.handlerRegistry = new ServletWebSocketHandlerRegistry();
			registerWebSocketHandlers(this.handlerRegistry);
		}
		return this.handlerRegistry;
	}

	protected void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
	}

	/**
	 * The default TaskScheduler to use if none is registered explicitly via
	 * {@link SockJsServiceRegistration#setTaskScheduler}:
	 * <pre class="code">
	 * &#064;Configuration
	 * &#064;EnableWebSocket
	 * class WebSocketConfig implements WebSocketConfigurer {
	 *
	 *   void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
	 *     registry.addHandler(myHandler(), "/echo")
	 *             .withSockJS()
	 *             .setTaskScheduler(myScheduler());
	 *   }
	 *
	 *   // ...
	 * }
	 * </pre>
	 */
	
	
	// TaskScheduler defaultSockJsTaskScheduler() {
	// 	if (initHandlerRegistry().requiresTaskScheduler()) {
	// 		ThreadPoolTaskScheduler threadPoolScheduler = new ThreadPoolTaskScheduler();
	// 		threadPoolScheduler.setThreadNamePrefix("SockJS-");
	// 		threadPoolScheduler.setPoolSize(Runtime.getRuntime().availableProcessors());
	// 		threadPoolScheduler.setRemoveOnCancelPolicy(true);
	// 		this.scheduler = threadPoolScheduler;
	// 	}
	// 	return this.scheduler;
	// }

}
