module hunt.framework.provider.lisener.ServiceProviderListener;

alias ListenHandler = void delegate();

/**
 * 
 */
interface ServiceProviderListener
{
    // The provider's type
    void registered(TypeInfo_Class providerType);

    // The provider's type
    void booted(TypeInfo_Class providerType);

    // The provider's type
    void listen(TypeInfo_Class providerType, ListenHandler handler);
}
