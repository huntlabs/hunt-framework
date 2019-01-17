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

module hunt.framework.websocket.server.WebSocketHandlerMapping;

// import javax.servlet.ServletContext;

// import hunt.util.SmartLifecycle;
// import hunt.framework.context.SmartLifecycle;
// import hunt.framework.web.context.ServletContextAware;
// import hunt.framework.web.servlet.handler.SimpleUrlHandlerMapping;

/**
 * An extension of {@link SimpleUrlHandlerMapping} that is also a
 * {@link SmartLifecycle} container and propagates start and stop calls to any
 * handlers that implement {@link Lifecycle}. The handlers are typically expected
 * to be {@code WebSocketHttpRequestHandler} or {@code SockJsHttpRequestHandler}.
 *
 * @author Rossen Stoyanchev
 * @since 4.2
 */
public class WebSocketHandlerMapping { // extends SimpleUrlHandlerMapping implements SmartLifecycle 

	private bool running = false;


	// override
	// protected void initServletContext(ServletContext servletContext) {
	// 	for (Object handler : getUrlMap().values()) {
	// 		if (handler instanceof ServletContextAware) {
	// 			((ServletContextAware) handler).setServletContext(servletContext);
	// 		}
	// 	}
	// }


	// override
	// public void start() {
	// 	if (!isRunning()) {
	// 		this.running = true;
	// 		for (Object handler : getUrlMap().values()) {
	// 			if (handler instanceof Lifecycle) {
	// 				((Lifecycle) handler).start();
	// 			}
	// 		}
	// 	}
	// }

	// override
	// public void stop() {
	// 	if (isRunning()) {
	// 		this.running = false;
	// 		for (Object handler : getUrlMap().values()) {
	// 			if (handler instanceof Lifecycle) {
	// 				((Lifecycle) handler).stop();
	// 			}
	// 		}
	// 	}
	// }

	// override
	// public bool isRunning() {
	// 	return this.running;
	// }

}
