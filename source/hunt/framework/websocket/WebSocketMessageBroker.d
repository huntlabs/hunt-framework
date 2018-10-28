
module hunt.framework.websocket.WebSocketMessageBroker;

import hunt.framework.context.ApplicationContext;
import hunt.framework.messaging.simp.config.MessageBrokerRegistry;
import hunt.framework.websocket.config.annotation.WebSocketMessageBrokerConfiguration;

import hunt.http.codec.websocket.frame.Frame;
import hunt.http.codec.websocket.stream.AbstractWebSocketBuilder;
import hunt.http.codec.websocket.stream.WebSocketConnection;
import hunt.http.codec.websocket.stream.WebSocketPolicy;
import hunt.http.server.WebSocketHandler;
import hunt.lang.common;

/**
*/
class WebSocketMessageBroker  { // : AbstractWebSocketBuilder
    // protected string path;
    // protected Action1!(MessageBrokerRegistry) _configurationHandler;
    // protected Action1!(StompEndpointRegistry) _endpointRegistryHandler;
    protected Action1!(WebSocketConnection) _connectHandler;
    private WebSocketMessageBrokerConfiguration brokerConfiguration;
    private ApplicationContext appContext;

    this(ApplicationContext context) {
        this.appContext = context;
        // this.path = path;
        brokerConfiguration = new WebSocketMessageBrokerConfiguration(context);
    }


    WebSocketMessageBroker onConfiguration(Action1!(MessageBrokerRegistry) handler) {
        // this._configurationHandler = handler;
        brokerConfiguration.messageBrokerRegistryHandler = handler;
        return this;
    }

	WebSocketMessageBroker onStompEndpointsRegister(Action1!(StompEndpointRegistry) handler) {
		brokerConfiguration.endpointRegistryHandler = handler;
        return this;
	}

    // WebSocketBuilder onConnect(Action1!(WebSocketConnection) handler) {
    //     this._connectHandler = handler;
    //     return this;
    // }

    // override WebSocketBuilder onText(Action2!(string, WebSocketConnection) handler) {
    //     super.onText(handler);
    //     return this;
    // }

    // override WebSocketBuilder onData(Action2!(ByteBuffer, WebSocketConnection) handler) {
    //     super.onData(handler);
    //     return this;
    // }

    // override WebSocketBuilder onError(Action2!(Throwable, WebSocketConnection) handler) {
    //     super.onError(handler);
    //     return this;
    // }

    // alias onError = AbstractWebSocketBuilder.onError;

    // private WebSocketHandler subProtocolWebSocketHandler() {
	// 	return new SubProtocolWebSocketHandler(clientInboundChannel(), clientOutboundChannel());
	// }

    void start() {
        appContext.start();
    }

    void listen() {
        brokerConfiguration.stompWebSocketHandlerMapping();
        brokerConfiguration.webSocketMessageBrokerStats();
    //     appContext.registerWebSocket(path, new class WebSocketHandler {

    //         override void onConnect(WebSocketConnection webSocketConnection) {
    //             if(_connectHandler !is null) 
    //                 _connectHandler(webSocketConnection);
    //         }

    //         override void onFrame(Frame frame, WebSocketConnection connection) {
    //             this.outer.onFrame(frame, connection);
    //         }

    //         override void onError(Exception t, WebSocketConnection connection) {
    //             this.outer.onError(t, connection);
    //         }
    //     });

    //     // router().addRoute("*", path, handler( (ctx) { })); 
    }

}