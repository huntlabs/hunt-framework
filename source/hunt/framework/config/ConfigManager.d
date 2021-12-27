module hunt.framework.config.ConfigManager;

import hunt.framework.application.HostEnvironment;
import hunt.framework.config.ApplicationConfig;
import hunt.framework.Init;

import hunt.logging;
import hunt.util.Configuration;

import std.exception;
import std.format;
import std.file;
import std.path;
import std.process;
import std.string;
import std.traits;

/** 
 * 
 */
class ConfigManager {

    // TODO: Tasks pending completion -@zhangxueping at 2020-03-11T16:53:58+08:00
    // thread-safe
    private Object[string] _cachedConfigs;
    private HostEnvironment _environment;

    this() {
        _environment = new HostEnvironment();
    }

    HostEnvironment hostEnvironment() {
        return _environment;
    }

    ConfigManager hostEnvironment(HostEnvironment value) {
        _environment = value;
        return this;
    }

    T load(T)() {
        static if (hasUDA!(T, ConfigurationFile)) {
            enum string fileBaseName = getUDAs!(T, ConfigurationFile)[0].name;
        } else {
            enum string fileBaseName = toLower(T.stringof);
        }

        return load!T(fileBaseName);
    }

    T load(T)(string baseName, string section="", bool isEnvironmentEnabled = true) {

        // get from the cache
        auto itemPtr = baseName in _cachedConfigs;
        if (itemPtr !is null) {
            return cast(T)*itemPtr;
        }

        string defaultConfigFile = baseName ~ DEFAULT_CONFIG_EXT;
        string fileName = defaultConfigFile;

        if(isEnvironmentEnabled) {
            string env = _environment.name();
            if (!env.empty) {
                fileName = baseName ~ "." ~ env ~ DEFAULT_CONFIG_EXT;
            }            
        }

        string _basePath = hostEnvironment.configPath();

        // Use the environment virable to set the base path
        string configBase = environment.get(ENV_CONFIG_BASE_PATH, "");
        if (!configBase.empty) {
            _basePath = configBase;
        }

        T currentConfig;
        ConfigBuilder defaultBuilder;
        string fullName = buildPath(APP_PATH, _basePath, fileName);

        if (exists(fullName)) {
            version(HUNT_DEBUG) infof("Loading config from: %s", fullName);
            defaultBuilder = new ConfigBuilder(fullName, section);
            currentConfig = defaultBuilder.build!(T)();
        } else {
            version(HUNT_DEBUG) {
                warningf("The config file does NOT exist (Use the default instead): %s", fullName);
            }
            fileName = defaultConfigFile;
            fullName = buildPath(APP_PATH, _basePath, fileName);
            if (exists(fullName)) {
                version(HUNT_DEBUG) infof("Loading config from: %s", fullName);
                defaultBuilder = new ConfigBuilder(fullName, section);
                currentConfig = defaultBuilder.build!(T)();
            } else {
                warningf("The config file does NOT exist (Use the default instead): %s", fullName);
                defaultBuilder = new ConfigBuilder();
                currentConfig = new T();
            }
        }

        _cachedConfigs[baseName] = currentConfig;

        return currentConfig;
    }
}
