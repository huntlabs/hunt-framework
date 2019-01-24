module hunt.framework.application.ApplicationContext;

import hunt.framework.application.ApplicationEvent;

import hunt.http.server.WebSocketHandler;

interface ApplicationContext : ApplicationEventPublisher {
    void start();

    ApplicationContext registerWebSocket(string path, WebSocketHandler handler);
}