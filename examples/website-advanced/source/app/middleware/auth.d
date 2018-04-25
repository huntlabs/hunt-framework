
module app.middleware.auth;

import hunt;
import std.experimental.logger;

class AuthMiddleware : IMiddleware
{
    string name()
    {
        return "AuthMiddleware";
    }

    Response onProcess(Request request, Response response)
    {
        bool allowed = false;

        if (!allowed)
        {
            if (response is null)
            {
                trace("createResponse");
                response = request.createResponse();
            }

            trace("setHttpStatusCode to 403");
            response.setHttpError(403);

            return response;
        }

        return null;
    }
}
