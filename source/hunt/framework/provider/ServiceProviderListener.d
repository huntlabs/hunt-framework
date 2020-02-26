module hunt.framework.provider.ServiceProviderListener;

interface ServiceProviderListener
{
    void registered(TypeInfo_Class info);  // 
    
    void booted(TypeInfo_Class info);  // provider type
}
