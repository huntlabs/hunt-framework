module hunt.router.router;



class Router(REQ, RES)
{
    alias HandleDelegate = void delegate(REQ, RES);
    
    bool addRouter(string path,HandleDelegate handle)
}