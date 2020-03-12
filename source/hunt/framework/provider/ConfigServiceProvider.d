module hunt.framework.provider.ConfigServiceProvider;

import hunt.framework.application.ApplicationConfig;
import hunt.framework.application.ConfigManager;
import hunt.framework.application.RouteConfig;
import hunt.framework.provider.ServiceProvider;
import hunt.framework.Init;

import hunt.logging.ConsoleLogger;
import poodinis;

import std.array;
import std.file;
import std.path;
import std.parallelism : totalCPUs;
import std.process;
import std.range;


/**
 * 
 */
class ConfigServiceProvider : ServiceProvider {

    private ApplicationConfig appConfig;

    override void register() {
        container.register!(ConfigManager).singleInstance();

        container.register!(ApplicationConfig)(() {
            ConfigManager configManager = container.resolve!(ConfigManager)();
            return configManager.load!(ApplicationConfig);
        }).singleInstance();

        container.register!(RouteConfig)(() {
            ConfigManager configManager = container.resolve!(ConfigManager)();
            ApplicationConfig appConfig = container.resolve!(ApplicationConfig)();
            RouteConfig routeConfig = new RouteConfig(appConfig);
            routeConfig.basePath = configManager.configPath();

            return routeConfig;
        });
    }

    override void boot() {
        ApplicationConfig appConfig = container.resolve!ApplicationConfig();
        checkWorkerThreads(appConfig);
        
        // update the config item with the environment variable if it exists
        string value = environment.get(ENV_APP_NAME, "");
        if(!value.empty) {
            appConfig.application.name = value;
        }

        // value = environment.get(ENV_APP_VERSION, "");
        // if(!value.empty) {
        //     appConfig.application.version = value;
        // }

        value = environment.get(ENV_APP_LANG, "");
        if(!value.empty) {
            appConfig.application.defaultLanguage = value;
        }

        value = environment.get(ENV_APP_KEY, "");
        if(!value.empty) {
            appConfig.application.secret = value;
        }
    }

    private void checkWorkerThreads(ApplicationConfig appConfig) {
        
        // Worker pool
        int minThreadCount = totalCPUs / 4 + 1;
        if (appConfig.http.workerThreads == 0)
            appConfig.http.workerThreads = minThreadCount;

        if (appConfig.http.workerThreads < minThreadCount) {
            warningf("It's better to set the number of worker threads >= %d. The current is: %d",
                    minThreadCount, appConfig.http.workerThreads);
            // appConfig.http.workerThreads = minThreadCount;
        }

        if (appConfig.http.workerThreads <= 1) {
            appConfig.http.workerThreads = 2;
        }
    }
}