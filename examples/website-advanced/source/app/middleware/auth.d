
module app.middleware.auth;

import hunt;

class AuthMiddleware : IMiddleware
{
    string name()
    {
        return "AuthMiddleware";
    }

    Response onProcess(Request request, Response response = null)
    {
        bool allowed = false;

        if (allowed)
        {
            if (response is null)
            {
                response = request.createResponse();
            }
            
            response.setHttpStatusCode(403);

            return response;
        }

        return null;
    }
}
