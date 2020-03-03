module hunt.framework.http.NotFoundResponse;

// import hunt.framework.http.Request;
import hunt.framework.http.Response;
import hunt.http.server;

import std.range;

/**
 * 
 */
class NotFoundResponse : HttpServerResponse {
    this(string content = null) {
        setStatus(404);

        if (content.empty)
            content = errorPageHtml(404);

        HttpBody hb = HttpBody.create(MimeType.TEXT_HTML_VALUE, content);
        setBody(hb);
    }
}
