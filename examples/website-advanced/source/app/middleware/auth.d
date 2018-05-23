
module app.middleware.auth;

import hunt;
import kiss.logger;

class AuthMiddleware : Middleware
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
                logDebug("createResponse");
                response = request.createResponse();
            }

            logDebug("setHttpStatusCode to 403");
            response.setHttpError(403);

            return response;
        }

        return null;
    }
}
