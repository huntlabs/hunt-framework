module hunt.framework.security.acl.AuthenticateMiddleware;

import hunt.framework.http.Request;
import hunt.framework.http.Response;
import hunt.framework.application.Application;
import hunt.framework.security.acl.AuthenticateInterface;

class AuthenticateMiddleware : Middleware
{
    this(AuthenticateInterface auth)
    {
       app().accessManager.initAuthenticate(auth);
    }

    
    static void saveIdtoSession(Request request , int id)
    {
        request.session.put("auth_userid" , to!string(id));
    }

    
    string name()
    {
        return "auth";
    }

    Response onProcess(Request request, Response response = null)
    {
       if(checkAuth(request))
            return null;

        auto mca = getMCA(request);
        
        auto permission = Application.getInstance().accessManager.getPermission(mca);
        response = new Response(request);
        if(permission !is null)
            response.do403("no permission: " ~ permission.name  ~ " mca: " ~ mca );
        else
            response.do403("database no this permission :" ~ mca);
        return response;
    }



protected{

    static int  getIdfromSession(Request request)
    {
        return to!int(request.session.get("auth_userid"));
    } 

    static bool existIdfromSession(Request request)
    {
        if(request.session is null)
            return false;

        return request.session.exists("auth_userid");
    }

    string getMCA(Request request)
    {
       auto modu = request.route.getModule();
       if(modu == string.init)
            return request.route.getController() ~ "." ~ request.route.getAction();
       else
            return request.route.getModule() ~ "." ~ request.route.getController()
                ~ "." ~ request.route.getAction();
    }

    bool checkAuth(Request request)
    {
        if(!existIdfromSession(request))
            return false;

        auto id = getIdfromSession(request);
        auto user = app().accessManager.getUser(id);
        if(user is null || ! user.can(getMCA(request)))
            return false;
        return true;
    }
}

    
}
