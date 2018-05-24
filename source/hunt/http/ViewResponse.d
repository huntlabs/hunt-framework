module hunt.http.ViewResponse;

import std.array;
import std.conv;
import std.datetime;
import std.json;
import std.path;
import std.file;

import collie.codec.http.headers.httpcommonheaders;
import collie.codec.http.server.responsehandler;
import collie.codec.http.server.responsebuilder;
import collie.codec.http.httpmessage;
import kiss.logger;
import hunt.http.cookie;
import hunt.utils.string;
import hunt.versions;
import hunt.http.response;
import hunt.view;


/**
 * Response represents an HTTP response in Html format.
 */
class ViewResponse : Response
{
    this(string contentType = HtmlContentType)
    {
        super();
        setHeader(HTTPHeaderCode.CONTENT_TYPE, contentType);
    }

    this(string content, string contentType = HtmlContentType)
    {
        this(contentType);
        setContent(content);
    }

    this(string templateFile, ref JSONValue model, string contentType = HtmlContentType)
    {
        this(contentType);

        if(extension(templateFile).empty)
            templateFile = setExtension(templateFile, ".dhtml");
		string content = Env().render_file(templateFile, model);
        setContent(content);
    }

}
