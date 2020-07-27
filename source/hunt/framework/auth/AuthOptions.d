module hunt.framework.auth.AuthOptions;

import hunt.http.AuthenticationScheme;

enum string DEFAULT_GURAD_NAME = "default";
enum string BASIC_COOKIE_NAME = "__basic_token__";
enum string BEARER_COOKIE_NAME = "__jwt_token__";


class AuthOptions {
    string guardName = DEFAULT_GURAD_NAME;
    string tokenCookieName = BEARER_COOKIE_NAME;
    AuthenticationScheme scheme = AuthenticationScheme.None;
}