module hunt.framework.auth.AuthOptions;

// import hunt.http.AuthenticationScheme;

enum string DEFAULT_GURAD_NAME = "default";
enum string BASIC_COOKIE_NAME = "__basic_token__";
enum string JWT_COOKIE_NAME = "__jwt_token__";

enum int DEFAULT_TOKEN_EXPIRATION = 30; // days


// class AuthOptions {
//     string guardName = DEFAULT_GURAD_NAME;

//     string tokenCookieName = JWT_COOKIE_NAME;
    
//     AuthenticationScheme scheme = AuthenticationScheme.Bearer;

//     uint tokenExpiration = DEFAULT_TOKEN_EXPIRATION*24*60*60; 
// }