
module hunt.framework.websocket.WebSocketMessageBroker;

import hunt.framework.context.ApplicationContext;
import hunt.framework.messaging.simp.config.MessageBrokerRegistry;
import hunt.framework.websocket.config.annotation.StompEndpointRegistry;
import hunt.framework.websocket.config.annotation.WebSocketMessageBrokerConfiguration;

import hunt.http.codec.websocket.frame.Frame;
import hunt.http.codec.websocket.stream.AbstractWebSocketBuilder;
import hunt.http.codec.websocket.stream.WebSocketConnection;
import hunt.http.codec.websocket.stream.WebSocketPolicy;
import hunt.http.server.WebSocketHandler;
import hunt.lang.common;

/**
*/
class WebSocketMessageBroker  { 
    protected Action1!(WebSocketConnection) _connectHandler;
    private WebSocketMessageBrokerConfiguration brokerConfiguration;
    private ApplicationContext appContext;

    this(ApplicationContext context) {
        this.appContext = context;
        brokerConfiguration = new WebSocketMessageBrokerConfiguration(context);
    }


    WebSocketMessageBroker onConfiguration(Action1!(MessageBrokerRegistry) handler) {
        brokerConfiguration.messageBrokerRegistryHandler = handler;
        return this;
    }

	WebSocketMessageBroker onStompEndpointsRegister(Action1!(StompEndpointRegistry) handler) {
		brokerConfiguration.endpointRegistryHandler = handler;
        return this;
	}


    void start() {
        appContext.start();
    }

    void listen() {
        brokerConfiguration.stompWebSocketHandlerMapping();
        // brokerConfiguration.webSocketMessageBrokerStats();
        brokerConfiguration.simpAnnotationMethodMessageHandler(); 
    }

}