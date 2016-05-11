module hunt.router.router;



class Router(REQUEST,RESPONSE)
{
    alias HandleDelegate = void delegate(REQUEST,RESPONSE);
    
    bool addRouter(string path,HandleDelegate handle)
}