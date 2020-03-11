module hunt.framework.provider.ConfigServiceProvider;

import hunt.framework.application.ApplicationConfig;
import hunt.framework.application.ConfigManager;
import hunt.framework.provider.ServiceProvider;
import hunt.framework.Init;

import hunt.logging.ConsoleLogger;
import poodinis;

import std.parallelism : totalCPUs;
import std.process;
import std.range;

/**
 * 
 */
class ConfigServiceProvider : ServiceProvider {

    private ApplicationConfig _appConfig;

    override void register() {
        container.register!(ConfigManager).singleInstance();

        container.register!(ApplicationConfig)(() {
            ConfigManager configManager = container.resolve!(ConfigManager)();
            ApplicationConfig config = configManager.load!(ApplicationConfig);
            return config;
        }).singleInstance();
    }

    override void boot() {
        _appConfig = container.resolve!ApplicationConfig();
        checkWorkerThreads();

        
        // update the config item with the environment variable if it exists
        string value = environment.get(ENV_APP_NAME, "");
        if(!value.empty) {
            _appConfig.application.name = value;
        }

        // value = environment.get(ENV_APP_VERSION, "");
        // if(!value.empty) {
        //     _appConfig.application.version = value;
        // }

        value = environment.get(ENV_APP_LANG, "");
        if(!value.empty) {
            _appConfig.application.defaultLanguage = value;
        }

        value = environment.get(ENV_APP_KEY, "");
        if(!value.empty) {
            _appConfig.application.secret = value;
        }
    }

    private void checkWorkerThreads() {
        
        // Worker pool
        int minThreadCount = totalCPUs / 4 + 1;
        if (_appConfig.http.workerThreads == 0)
            _appConfig.http.workerThreads = minThreadCount;

        if (_appConfig.http.workerThreads < minThreadCount) {
            warningf("It's better to set the number of worker threads >= %d. The current is: %d",
                    minThreadCount, _appConfig.http.workerThreads);
            // _appConfig.http.workerThreads = minThreadCount;
        }

        if (_appConfig.http.workerThreads <= 1) {
            _appConfig.http.workerThreads = 2;
        }
    }
}