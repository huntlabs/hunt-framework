module hunt.application.web.app;

version(USE_DEFAULT_WEB_MAIN):

import hunt.application.web.application;
import hunt.application.web.config;

void main()
{
    auto app = WebApplication.app();
    if(app is null)
    {
        WebApplication.setConfig(new WebConfig());
        app = WebApplication.app();
    }
    app.run();
}