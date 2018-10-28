module hunt.framework.context.ApplicationContext;

import hunt.http.server.WebSocketHandler;

interface ApplicationContext {
    void start();
    
    void registerWebSocket(string path, WebSocketHandler handler);
}