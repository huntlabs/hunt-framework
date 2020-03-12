module hunt.framework.application.ConfigManager;

import hunt.framework.application.ApplicationConfig;
import hunt.framework.Init;

import hunt.logging.ConsoleLogger;
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
    private string _basePath = DEFAULT_CONFIG_LACATION;

    this() {
        _basePath = DEFAULT_CONFIG_PATH;
    }

    string configPath() {
        return this._basePath;
    }

    ConfigManager configPath(string path) {
        if (path.empty)
            return this;

        if (path[$ - 1] == '/')
            this._basePath = path;
        else
            this._basePath = path ~ "/";

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

    T load(T)(string baseName, string section="") {

        // get from the cache
        auto itemPtr = baseName in _cachedConfigs;
        if (itemPtr !is null) {
            return cast(T)*itemPtr;
        }

        // Use the environment virable to set the base path
        string configBase = environment.get(ENV_CONFIG_BASE_PATH, "");
        if (!configBase.empty) {
            _basePath = configBase;
        }

        // Try to load the config based on environment settings firstly.
        string fileName = baseName ~ DEFAULT_CONFIG_EXT;
        string huntEnv = environment.get("HUNT_ENV", "");
        if (huntEnv.empty) {
            huntEnv = environment.get(ENV_APP_ENV, "");
        }

        version (HUNT_FM_DEBUG)
            tracef("%s=%s", ENV_APP_ENV, huntEnv);

        if (!huntEnv.empty) {
            fileName = baseName ~ "." ~ huntEnv ~ DEFAULT_CONFIG_EXT;
        }

        T currentConfig;
        ConfigBuilder defaultBuilder;
        string fullName = buildPath(APP_PATH, _basePath, fileName);
        if (exists(fullName)) {
            infof("Loading config from: %s", fullName);
            defaultBuilder = new ConfigBuilder(fullName, section);
            currentConfig = defaultBuilder.build!(T)();
        } else {
            fileName = baseName ~ DEFAULT_CONFIG_EXT;
            fullName = buildPath(APP_PATH, _basePath, fileName);
            if (exists(fullName)) {
                infof("Loading config from: %s", fullName);
                defaultBuilder = new ConfigBuilder(fullName, section);
                currentConfig = defaultBuilder.build!(T)();
            } else {
                warningf("The configure file does not exist (Use the default instead): %s",
                        fullName);
                defaultBuilder = new ConfigBuilder();
                currentConfig = new T();
            }
        }

        _cachedConfigs[baseName] = currentConfig;

        return currentConfig;
    }
}
