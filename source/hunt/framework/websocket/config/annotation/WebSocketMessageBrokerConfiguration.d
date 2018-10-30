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

module hunt.framework.websocket.config.annotation.WebSocketMessageBrokerConfiguration;

import hunt.framework.websocket.config.annotation.StompEndpointRegistry;
import hunt.framework.websocket.config.annotation.WebSocketTransportRegistration;

// import hunt.framework.beans.factory.config.CustomScopeConfigurer;
import hunt.framework.context.ApplicationContext;
// import hunt.framework.context.annotation.Bean;
// import hunt.framework.http.converter.json.Jackson2ObjectMapperBuilder;

// import hunt.framework.messaging.converter.MappingJackson2MessageConverter;
import hunt.framework.messaging.simp.SimpSessionScope;
import hunt.framework.messaging.simp.annotation.SimpAnnotationMethodMessageHandler;
import hunt.framework.messaging.simp.broker.AbstractBrokerMessageHandler;
import hunt.framework.messaging.simp.config.AbstractMessageBrokerConfiguration;
import hunt.framework.messaging.simp.config.MessageBrokerRegistry;
import hunt.framework.messaging.simp.stomp.StompBrokerRelayMessageHandler;
// import hunt.framework.messaging.simp.user.SimpUserRegistry;
// import hunt.framework.web.servlet.HandlerMapping;
// import hunt.framework.websocket.config.WebSocketMessageBrokerStats;
// import hunt.framework.websocket.handler.WebSocketHandlerDecoratorFactory;
// import hunt.framework.websocket.messaging.DefaultSimpUserRegistry;
import hunt.framework.websocket.messaging.SubProtocolWebSocketHandler;
import hunt.framework.websocket.messaging.WebSocketAnnotationMethodMessageHandler;

import hunt.http.server.WebSocketHandler;

import hunt.lang.common;


/**
 * Extends {@link AbstractMessageBrokerConfiguration} and adds configuration for
 * receiving and responding to STOMP messages from WebSocket clients.
 *
 * <p>Typically used in conjunction with
 * {@link EnableWebSocketMessageBroker @EnableWebSocketMessageBroker} but can
 * also be extended directly.
 *
 * @author Rossen Stoyanchev
 * @author Artem Bilan
 * @since 4.0
 */
class WebSocketMessageBrokerConfiguration : AbstractMessageBrokerConfiguration {
	
	private WebSocketTransportRegistration transportRegistration;
	Action1!(StompEndpointRegistry) endpointRegistryHandler;
	Action1!(MessageBrokerRegistry) messageBrokerRegistryHandler;

	this(ApplicationContext context) {

	}

	// void onStompEndpointsRegister(Action1!(StompEndpointRegistry) handler) {
	// 	endpointRegistryHandler = handler;
	// }


	override
	protected SimpAnnotationMethodMessageHandler createAnnotationMethodMessageHandler() {
		return new WebSocketAnnotationMethodMessageHandler(
				clientInboundChannel(), clientOutboundChannel(), brokerMessagingTemplate());
	}

	// override
	// protected SimpUserRegistry createLocalUserRegistry(int order) {
	// 	DefaultSimpUserRegistry registry = new DefaultSimpUserRegistry();
	// 	if (order !is null) {
	// 		registry.setOrder(order);
	// 	}
	// 	return registry;
	// }

// TODO: Tasks pending completion -@zxp at 10/30/2018, 2:42:18 PM
// 
	// HandlerMapping stompWebSocketHandlerMapping() {
	// 	WebSocketHandler handler = decorateWebSocketHandler(subProtocolWebSocketHandler());
	// 	WebMvcStompEndpointRegistry registry = new WebMvcStompEndpointRegistry(
	// 			handler, getTransportRegistration(), messageBrokerTaskScheduler());
	// 	ApplicationContext applicationContext = getApplicationContext();
	// 	if (applicationContext !is null) {
	// 		registry.setApplicationContext(applicationContext);
	// 	}
	// 	registerStompEndpoints(registry);
	// 	return registry.getHandlerMapping();
	// }

	void stompWebSocketHandlerMapping() {
		WebSocketHandler handler = decorateWebSocketHandler(subProtocolWebSocketHandler());
		WebMvcStompEndpointRegistry registry = new WebMvcStompEndpointRegistry(
				handler, getTransportRegistration(), messageBrokerTaskScheduler());
		ApplicationContext applicationContext = getApplicationContext();
		if (applicationContext !is null) {
			registry.setApplicationContext(applicationContext);
		}
		registerStompEndpoints(registry);
		// return registry.getHandlerMapping();
	}	
	
	WebSocketHandler subProtocolWebSocketHandler() {
		return new SubProtocolWebSocketHandler(clientInboundChannel(), clientOutboundChannel());
	}

	protected WebSocketHandler decorateWebSocketHandler(WebSocketHandler handler) {
		foreach (WebSocketHandlerDecoratorFactory factory ; getTransportRegistration().getDecoratorFactories()) {
			handler = factory.decorate(handler);
		}
		return handler;
	}

	protected final WebSocketTransportRegistration getTransportRegistration() {
		if (this.transportRegistration is null) {
			this.transportRegistration = new WebSocketTransportRegistration();
			configureWebSocketTransport(this.transportRegistration);
		}
		return this.transportRegistration;
	}

	protected void configureWebSocketTransport(WebSocketTransportRegistration registry) {
	}

	protected abstract void registerStompEndpoints(StompEndpointRegistry registry) {
		if(endpointRegistryHandler !is null)
			endpointRegistryHandler(registry);
	}

	override
	protected void configureMessageBroker(MessageBrokerRegistry registry) {
		if(messageBrokerRegistryHandler !is null)
			messageBrokerRegistryHandler(registry);
	}
	
	// static CustomScopeConfigurer webSocketScopeConfigurer() {
	// 	CustomScopeConfigurer configurer = new CustomScopeConfigurer();
	// 	configurer.addScope("websocket", new SimpSessionScope());
	// 	return configurer;
	// }

	
	// WebSocketMessageBrokerStats webSocketMessageBrokerStats() {
	// 	AbstractBrokerMessageHandler relayBean = stompBrokerRelayMessageHandler();

	// 	// Ensure STOMP endpoints are registered
	// 	stompWebSocketHandlerMapping();

	// 	WebSocketMessageBrokerStats stats = new WebSocketMessageBrokerStats();
	// 	stats.setSubProtocolWebSocketHandler(cast(SubProtocolWebSocketHandler) subProtocolWebSocketHandler());
	// 	auto rb = cast(StompBrokerRelayMessageHandler) relayBean;
	// 	if (rb !is null) {
	// 		stats.setStompBrokerRelay(rb);
	// 	}
	// 	stats.setInboundChannelExecutor(clientInboundChannelExecutor());
	// 	stats.setOutboundChannelExecutor(clientOutboundChannelExecutor());
	// 	// stats.setSockJsTaskScheduler(messageBrokerTaskScheduler());
	// 	return stats;
	// }

	// override
	// protected MappingJackson2MessageConverter createJacksonConverter() {
	// 	MappingJackson2MessageConverter messageConverter = super.createJacksonConverter();
	// 	// Use Jackson builder in order to have JSR-310 and Joda-Time modules registered automatically
	// 	Jackson2ObjectMapperBuilder builder = Jackson2ObjectMapperBuilder.json();
	// 	ApplicationContext applicationContext = getApplicationContext();
	// 	if (applicationContext !is null) {
	// 		builder.applicationContext(applicationContext);
	// 	}
	// 	messageConverter.setObjectMapper(builder.build());
	// 	return messageConverter;
	// }

}
