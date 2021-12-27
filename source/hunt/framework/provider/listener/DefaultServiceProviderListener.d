module hunt.framework.provider.listener.DefaultServiceProviderListener;

import hunt.framework.provider.listener.ServiceProviderListener;
import hunt.logging;

/**
 * 
 */
class DefaultServiceProviderListener : ServiceProviderListener {
    private ListenHandler[TypeInfo_Class] _listenHandlers;

    void registered(TypeInfo_Class providerType) {
        version (HUNT_DEBUG)
            tracef("Service Provider Loaded: %s", providerType.toString());
    }

    void booted(TypeInfo_Class providerType) {
        version (HUNT_DEBUG)
            tracef("Service Provider Booted: %s", providerType.toString());

        this.handle(providerType);
    }

    void listen(TypeInfo_Class providerType, ListenHandler handler) {
        _listenHandlers[providerType] = handler;

        version (HUNT_DEBUG)
            tracef("Listen Service Provider: %s", providerType.toString());
    }

    void handle(TypeInfo_Class providerType) {
        auto handler = _listenHandlers.get(providerType, null);
        if (handler != null) {
            version (HUNT_DEBUG)
                tracef("Call Service Provider Handler: %s", providerType.toString());
            handler();
        }
    }
}
