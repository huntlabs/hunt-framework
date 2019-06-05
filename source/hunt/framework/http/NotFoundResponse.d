module hunt.framework.http.NotFoundResponse;

import hunt.framework.http.Request;
import hunt.framework.http.Response;

class NotFoundResponse : Response
{
    this(string content)
    {
        super(request());

        setStatus(404);
        setContent(content.length == 0 ? errorPageHtml(404) : content);
    }
}
