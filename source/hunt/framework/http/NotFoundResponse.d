module hunt.framework.http.NotFoundResponse;

import hunt.framework.http.HttpErrorResponseHandler;
import hunt.framework.http.Response;
import hunt.http.server;

import std.range;

/**
 * 
 */
class NotFoundResponse : Response {
    this(string content = null) {
        setStatus(404);

        if (content.empty)
            content = errorPageHtml(404);

        setContent(content, MimeType.TEXT_HTML_VALUE);
    }
}
