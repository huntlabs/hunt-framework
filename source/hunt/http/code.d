module hunt.http.code;

enum HTTPCodes {
	CONTINUE                        = 100,
	SWITCHING_PROTOCOLS             = 101,
	OK                              = 200,
	CREATED                         = 201,
	ACCEPTED                        = 202,
    NON_AUTHORITATIVE_INFORMATION   = 203,
    NO_CONTENT                      = 204,
    RESET_CONTENT                   = 205,
    PARTIAL_CONTENT                 = 206,

    MULTIPLE_CHOICES                = 300,
    MOVED_PERMANENTLY               = 301,
    FOUND                           = 302,
    SEE_OTHER                       = 303,
    NOT_MODIFIED                    = 304,
    USE_PROXY                       = 305,
    TEMPORARY_REDIRECT              = 307,

    BAD_REQUEST                     = 400,
    UNAUTHORIZED                    = 401,
    PAYMENT_REQUIRED                = 402,
    FORHIDDEN                       = 403,
    NOT_FOUND                       = 404,
    METHOD_NOT_ALLOWED              = 405,
    NOT_ACCEPTABLE                  = 406,
    PROXY_AUTHENTICATION_REQUIRED   = 407,
    REQUEST_TIMEOUT                 = 408,
    CONFLICT                        = 409,
    GONE                            = 410,
    LENGTH_REQUIRED                 = 411,
    PRECONDITION_FAILED             = 412,
    REQUEST_ENTITY_TOO_LARGE        = 413,
    REQUEST_URI_TOO_LARGE           = 414,
    UNSUPPORTED_MEDIA_TYPE          = 415,
    REQUESTED_RANGE_NOT_SATISFIABLE = 416,
    EXPECTATION_FAILED              = 417,
    TOO_MANY_REQUESTS               = 429,
    UNAVAILABLE_FOR_LAGAL_REASONS   = 451,

    INTERNAL_SERVER_ERROR           = 500,
    NOT_IMPLEMENTED                 = 501,
    BAD_GATEWAY                     = 502,
    SERVICE_UNAVALIBALE             = 503,
    GATEWAY_TIMEOUT                 = 504,
    HTTP_VERSION_NOT_SUPPORTED      = 505,

    // for WebDAV
    MULI_STATUS                     = 207,
    UNPROCESSABLE_ENTITY            = 422,
    LOCKED                          = 423,
    FAILED_DEPENDENCY               = 424,
    INSUFFICIENT_STORAGE            = 507
}

@safe nothrow @nogc pure:

string HTTPCodeText(int code)
{
	switch(code)
	{
		default: break;
		case HTTPCodes.CONTINUE                         : return "Continue";
		case HTTPCodes.SWITCHING_PROTOCOLS              : return "Switching Protocols";
		case HTTPCodes.OK                               : return "OK";
		case HTTPCodes.CREATED                          : return "Created";
		case HTTPCodes.ACCEPTED                         : return "Accepted";
		case HTTPCodes.NON_AUTHORITATIVE_INFORMATION    : return "Non-Authoritative Information";
		case HTTPCodes.NO_CONTENT                       : return "No Content";
		case HTTPCodes.RESET_CONTENT                    : return "Reset Content";
		case HTTPCodes.PARTIAL_CONTENT                  : return "Partial Content";
		case HTTPCodes.MULTIPLE_CHOICES                 : return "Multiple Choices";
		case HTTPCodes.MOVED_PERMANENTLY                : return "Moved Permanently";
		case HTTPCodes.FOUND                            : return "Found";
		case HTTPCodes.SEE_OTHER                        : return "See Other";
		case HTTPCodes.NOT_MODIFIED                     : return "Not Modified";
		case HTTPCodes.USE_PROXY                        : return "Use Proxy";
		case HTTPCodes.TEMPORARY_REDIRECT               : return "Temporary Redirect";
		case HTTPCodes.BAD_REQUEST                      : return "Bad Request";
		case HTTPCodes.UNAUTHORIZED                     : return "Unauthorized";
		case HTTPCodes.PAYMENT_REQUIRED                 : return "Payment Required";
		case HTTPCodes.FORHIDDEN                        : return "Forbidden";
		case HTTPCodes.NOT_FOUND                        : return "Not Found";
		case HTTPCodes.METHOD_NOT_ALLOWED               : return "Method Not Allowed";
		case HTTPCodes.NOT_ACCEPTABLE                   : return "Not Acceptable";
		case HTTPCodes.PROXY_AUTHENTICATION_REQUIRED    : return "Proxy Authentication Required";
		case HTTPCodes.REQUEST_TIMEOUT                  : return "Request Time-out";
		case HTTPCodes.CONFLICT                         : return "Conflict";
		case HTTPCodes.GONE                             : return "Gone";
		case HTTPCodes.LENGTH_REQUIRED                  : return "Length Required";
		case HTTPCodes.PRECONDITION_FAILED              : return "Precondition Failed";
		case HTTPCodes.REQUEST_ENTITY_TOO_LARGE         : return "Request Entity Too Large";
		case HTTPCodes.REQUEST_URI_TOO_LARGE            : return "Request-URI Too Large";
		case HTTPCodes.UNSUPPORTED_MEDIA_TYPE           : return "Unsupported Media Type";
		case HTTPCodes.REQUESTED_RANGE_NOT_SATISFIABLE  : return "Requested range not satisfiable";
		case HTTPCodes.EXPECTATION_FAILED               : return "Expectation Failed";
		case HTTPCodes.UNAVAILABLE_FOR_LAGAL_REASONS    : return "Unavailable For Legal Reasons";
		case HTTPCodes.INTERNAL_SERVER_ERROR            : return "Internal Server Error";
		case HTTPCodes.NOT_IMPLEMENTED                  : return "Not Implemented";
		case HTTPCodes.BAD_GATEWAY                      : return "Bad Gateway";
		case HTTPCodes.SERVICE_UNAVALIBALE              : return "Service Unavailable";
		case HTTPCodes.GATEWAY_TIMEOUT                  : return "Gateway Time-out";
		case HTTPCodes.HTTP_VERSION_NOT_SUPPORTED       : return "HTTP Version not supported";
	    // WebDAV status codes
		case HTTPCodes.MULI_STATUS                      : return "Multi-Status";
		case HTTPCodes.UNPROCESSABLE_ENTITY             : return "Unprocessable Entity";
		case HTTPCodes.LOCKED                           : return "Locked";
		case HTTPCodes.FAILED_DEPENDENCY                : return "Failed Dependency";
		case HTTPCodes.INSUFFICIENT_STORAGE             : return "Insufficient Storage";
	}
	if( code >= 600 ) return "Unknown";
	if( code >= 500 ) return "Unknown server error";
	if( code >= 400 ) return "Unknown error";
	if( code >= 300 ) return "Unknown redirection";
	if( code >= 200 ) return "Unknown success";
	if( code >= 100 ) return "Unknown information";
	return "Unknown";
}

bool isSuccessCode(HTTPCodes code)
{
	return code >= 200 && code < 300;
}
