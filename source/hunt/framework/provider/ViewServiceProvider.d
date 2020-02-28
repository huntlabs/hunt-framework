module hunt.framework.provider.ViewServiceProvider;

import hunt.framework.application.ApplicationConfig;
import hunt.framework.provider.ServiceProvider;
import hunt.framework.Init;
import hunt.framework.view.View;
import hunt.framework.view.Environment;

import hunt.logging.ConsoleLogger;
import poodinis;

import std.path;

/**
 * 
 */
class ViewServiceProvider : ServiceProvider {

    private ApplicationConfig _appConfig;

    override void register() {

        container.register!(View)(() {
            auto view = new View(new Environment);
            string path = buildNormalizedPath(APP_PATH, _appConfig.view.path);

            version (HUNT_DEBUG) {
                tracef("Setting view path: %s", path);
            }

            view.setTemplatePath(path)
                .setTemplateExt(_appConfig.view.ext)
                .arrayDepth(_appConfig.view.arrayDepth);

            return view;
        }).newInstance();
    }

    override void boot() {
        _appConfig = container.resolve!ApplicationConfig();
    }
}