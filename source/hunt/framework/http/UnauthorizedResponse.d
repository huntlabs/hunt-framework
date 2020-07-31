module hunt.framework.http.UnauthorizedResponse;

import hunt.framework.http.HttpErrorResponseHandler;
import hunt.framework.http.Response;
import hunt.framework.application.Application;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.provider.ServiceProvider;
import hunt.framework.view.View;

import hunt.http.server;

import std.format;
import std.range;

/**
 * 
 */
class UnauthorizedResponse : Response {

    enum int StatusCode = 401;

    this(string content = null, bool isRestful = false, AuthenticationScheme authType = AuthenticationScheme.None) {
        setStatus(StatusCode);

        if(isRestful) {
            if(!content.empty) setContent(content, MimeType.APPLICATION_JSON_VALUE);
        } else {
            ApplicationConfig.AuthConf appConfig = app().config().auth;

            if(authType == AuthenticationScheme.Basic) {
                header(HttpHeader.WWW_AUTHENTICATE, format("Basic realm=\"%s\"", appConfig.basicRealm));
            }
            
            if (content.empty) {
                content = errorPageHtml(StatusCode);
            }

            setContent(content, MimeType.TEXT_HTML_VALUE);
        }

    }
}
