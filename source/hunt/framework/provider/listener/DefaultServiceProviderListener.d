module hunt.framework.provider.lisener.DefaultServiceProviderListener;

import hunt.framework.provider.lisener.ServiceProviderListener;

class DefaultServiceProviderListener : ServiceProviderListener
{
    private ListenHandler[TypeInfo_Class] _listenHandlers;

    void registered(TypeInfo_Class providerType)
    {
        tracef("Service Provider Loaded: %s", info.toString());
    }

    void booted(TypeInfo_Class providerType)
    {
        tracef("Service Provider Booted: %s", info.toString());

        this.handle(providerType);
    }

    void listen(TypeInfo_Class providerType, ListenHandler)
    {
        _listenHandlers[providerType] = ListenHandler;

        tracef("Listen Service Provider: %s", providerType.toString());
    }

    void handle(TypeInfo_Class providerType)
    {
        auto handler = _listenHandlers.get(providerType, null);
        if (handler != null)
        {
            tracef("Call Service Provider Handler: %s", providerType.toString());
            handler();
        }
    }
}
