module hunt.framework.http.HttpErrorResponseHandler;

import hunt.http.HttpHeader;
import hunt.http.HttpStatus;
import hunt.http.routing.handler.ErrorResponseHandler;
import hunt.http.routing.RoutingContext;

import std.range;


/**
 * 
 */
class HttpErrorResponseHandler : ErrorResponseHandler {

    override void render(RoutingContext context, int status, Exception t) {

        HttpStatusCode code = HttpStatus.getCode(status); 
        if(code == HttpStatusCode.Null)
            code = HttpStatusCode.INTERNAL_SERVER_ERROR;
        
        context.setStatus(status);
        context.getResponseHeaders().put(HttpHeader.CONTENT_TYPE, "text/html");
        context.end(errorPageHtml(status));
    }

}



// dfmt off
string errorPageHtml(int code , string _body = "")
{
    import std.conv : to;

    string text = code.to!string;
    text ~= " ";
    text ~= HttpStatus.getMessage(code);

    string html = `<!doctype html>
<html lang="en">
    <meta charset="utf-8">
    <title>`;

    html ~= text;
    html ~= `</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>

        * {
            line-height: 3;
            margin: 0;
        }

        html {
            color: #888;
            display: table;
            font-family: sans-serif;
            height: 100%;
            text-align: center;
            width: 100%;
        }

        body {
            display: table-cell;
            vertical-align: middle;
            margin: 2em auto;
        }

        h1 {
            color: #555;
            font-size: 2em;
            font-weight: 400;
        }

        p {
            margin: 0 auto;
            width: 90%;
        }

    </style>
</head>
<body>
    <h1>`;
    html ~= text;
    html ~= `</h1>
    <p>Sorry!! Unable to complete your request :(</p>
    `;
    if(_body.length > 0)
        html ~= "<p>" ~ _body ~ "</p>";
html ~= `
</body>
</html>
`;

    return html;
}

string errorPageWithStack(int code , string _body = "")
{
    import std.conv : to;

    string text = code.to!string;
    text ~= " ";
    text ~= HttpStatus.getMessage(code);

    string html = `<!doctype html>
<html lang="en">
    <meta charset="utf-8">
    <title>`;

    html ~= text;
    html ~= `</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
   
</head>
<body>
    <h1>`;
    html ~= text;
    html ~= `</h1>
    <p>Sorry!! Unable to complete your request :(</p>
    `;
    

    if(!_body.empty) {
        html ~= _body;
    }

    html ~= `
</body>
</html>
`;

    return html;
}
// dfmt on
