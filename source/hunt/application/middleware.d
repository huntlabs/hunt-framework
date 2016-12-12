module hunt.application.middleware;

import hunt.http.request;
import hunt.http.response;


interface IMiddleware
{
	///get the middleware name
	string name();
	///return true is continue, false is finish
	bool onProcess(Request req,Response res);
}
