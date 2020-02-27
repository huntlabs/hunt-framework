module hunt.framework.provider.ServiceProviderListener;

/**
 * 
 */
interface ServiceProviderListener {

    // The provider's type
    void registered(TypeInfo_Class info); 

    // The provider's type
    void booted(TypeInfo_Class info); 
}
