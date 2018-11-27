module hunt.framework.security.acl.AuthenticateMiddleware;

import hunt.framework.http.Request;
import hunt.framework.http.Response;
import hunt.framework.application.Application;

class AuthenticateMiddleware : Middleware
{
    this( string[] whiteList ...)
    {
       mcaList ~= whiteList;
    }

    string name()
    {
        return "auth";
    }

    Response onProcess(Request request, Response response = null)
    {
       import std.algorithm.searching;  
       auto mca = request.getMCA();
       auto white = find!(" a == b")(mcaList , mca);
       if( white.length > 0 )
            return null;

       auto am = app().accessManager;
       if(am.checkAuth())
            return null;
  
        auto permission = am.getPermission(mca);
        response = new Response(request);
        if(permission !is null)
            response.do403("no permission: " ~ permission.name  ~ " mca: " ~ mca );
        else
            response.do403("database no this permission :" ~ mca);
        return response;
    }

    protected string[] mcaList;
  
}
