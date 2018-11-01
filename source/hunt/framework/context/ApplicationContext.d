module hunt.framework.context.ApplicationContext;

import hunt.framework.context.ApplicationEvent;

import hunt.http.server.WebSocketHandler;

interface ApplicationContext : ApplicationEventPublisher {
    void start();
    
    ApplicationContext registerWebSocket(string path, WebSocketHandler handler);
}