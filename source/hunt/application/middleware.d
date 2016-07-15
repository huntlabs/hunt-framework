module hunt.application.middleware;

import hunt.http.request;
import hunt.http.response;


interface IMiddleware
{
	///return true is continue, false is finish
	bool onProcess(Request req, Response res);
}

///middleware factory
abstract shared class AbstractMiddlewareFactory
{
	IMiddleware[] getMiddlewares();
}
