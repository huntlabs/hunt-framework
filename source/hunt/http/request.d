module hunt.http.request;

import collie.codec.http;

import hunt.http.webfrom;

class Request
{

	private HTTPRequest _req;

	this(HTTPRequest req)
	{
		assert(req);
		_req = req;
	}
	WebForm postForm()
	{
		return new WebForm(_req);
	}


	@property httpRequest()
	{
		return _req;
	}
}
